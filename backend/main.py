"""FastAPI boundary for TruWave verification."""
from __future__ import annotations

from collections.abc import Sequence

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from backend.config import ConfigError, Settings, load_settings
from backend.verifier import Decision, VerificationUnavailable, Verifier
from evidence.base import EvidenceProvider
from evidence.fixture import FixtureEvidenceProvider
from evidence.google_factcheck import GoogleFactCheckProvider
from evidence.service import EvidenceService
from ml.base import MLClassifier
from ml.mock import MockClassifier


class VerifyRequest(BaseModel):
    claim: str = Field(min_length=1)


class Source(BaseModel):
    name: str
    title: str
    url: str


class VerifyResponse(BaseModel):
    verdict: str
    confidence: float
    summary: str
    findings: list[str]
    sources: list[Source]


def build_verifier(
    settings: Settings,
    *,
    ml_classifier: MLClassifier | None = None,
    evidence_providers: Sequence[EvidenceProvider] | None = None,
) -> Verifier:
    """Build the configured pipeline; classifier injection keeps the ML seam replaceable."""
    if ml_classifier is None:
        if settings.ml_provider != "mock":
            raise ConfigError("Configured ML classifier is not available")
        ml_classifier = MockClassifier()

    if evidence_providers is None:
        if settings.evidence_provider == "google":
            evidence_providers = [GoogleFactCheckProvider(
                settings.factcheck_api_key,
                language=settings.factcheck_language,
                page_size=settings.factcheck_page_size,
                timeout_s=settings.factcheck_timeout_s,
                max_attempts=settings.factcheck_max_attempts,
            )]
        elif settings.evidence_provider == "fixture":
            evidence_providers = [FixtureEvidenceProvider()]
        else:  # Settings validation normally makes this unreachable.
            raise ConfigError("Configured evidence provider is not available")

    evidence = EvidenceService(
        evidence_providers,
        min_relevance=settings.evidence_min_relevance,
        provider_timeout_s=settings.evidence_timeout_s,
    )
    return Verifier(
        ml_classifier,
        evidence,
        ml_timeout_s=settings.ml_timeout_s,
        ml_threshold=settings.ml_strong_threshold,
        max_sources=settings.max_sources,
    )


def _response(decision: Decision) -> VerifyResponse:
    return VerifyResponse(
        verdict=decision.verdict.value,
        confidence=decision.confidence,
        summary=decision.summary,
        findings=decision.findings,
        sources=[Source(name=s.name, title=s.title, url=s.url) for s in decision.sources],
    )


def create_app(
    *,
    settings: Settings | None = None,
    verifier: Verifier | None = None,
    ml_classifier: MLClassifier | None = None,
    evidence_providers: Sequence[EvidenceProvider] | None = None,
) -> FastAPI:
    settings = settings or load_settings()
    if verifier is None:
        verifier = build_verifier(
            settings, ml_classifier=ml_classifier, evidence_providers=evidence_providers
        )

    application = FastAPI()
    application.state.verifier = verifier
    application.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @application.post("/verify", response_model=VerifyResponse)
    async def verify(request: VerifyRequest, http_request: Request) -> VerifyResponse:
        try:
            decision = await http_request.app.state.verifier.verify(request.claim)
        except VerificationUnavailable:
            # Keep provider details, request URLs, and credentials out of the public response.
            raise HTTPException(
                status_code=503,
                detail="Verification is temporarily unavailable. Please try again.",
            ) from None
        return _response(decision)

    return application


app = create_app()
