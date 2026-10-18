import asyncio
import math
from dataclasses import replace
from types import SimpleNamespace

import httpx
import joblib
import pytest

from backend.config import ConfigError, load_settings
from backend.main import build_verifier, create_app
from evidence.base import EvidenceItem, ProviderAuthError, SourceTier, Stance
from evidence.google_factcheck import GoogleFactCheckProvider
from ml.base import MLLabel, MLResult, MLUnavailableError
from ml.tfidf import TfidfClassifier


class _LifespanClient:
    """Keep focused API tests exercising FastAPI startup and shutdown hooks."""

    def __init__(self, app):
        self.app = app

    def post(self, *args, **kwargs):
        async def request():
            async with self.app.router.lifespan_context(self.app):
                async with httpx.AsyncClient(
                    transport=httpx.ASGITransport(app=self.app),
                    base_url="http://test",
                ) as client:
                    return await client.post(*args, **kwargs)

        return asyncio.run(request())


def _settings(**env):
    return load_settings({"ML_PROVIDER": "mock", **env}, load_env_file=False)


def test_verify_uses_mock_classifier_and_fixture_evidence_with_public_contract():
    client = _LifespanClient(create_app(
        settings=_settings(EVIDENCE_PROVIDER="fixture")
    ))

    response = client.post("/verify", json={"claim": "Drinking bleach cures viral infections"})

    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"verdict", "confidence", "summary", "findings", "sources"}
    assert body["verdict"] == "FAKE"
    assert isinstance(body["confidence"], float)
    assert isinstance(body["summary"], str) and body["summary"]
    assert isinstance(body["findings"], list)
    assert body["sources"]
    assert all(set(source) == {"name", "title", "url"} for source in body["sources"])


def test_verify_returns_uncertain_when_no_direct_evidence_is_found():
    client = _LifespanClient(create_app(
        settings=_settings(EVIDENCE_PROVIDER="fixture")
    ))

    response = client.post("/verify", json={"claim": "An unreviewed claim with no matching evidence"})

    assert response.status_code == 200
    assert response.json()["verdict"] == "UNCERTAIN"
    assert response.json()["sources"] == []


def test_verify_returns_real_from_supporting_fixture_evidence():
    client = _LifespanClient(create_app(settings=_settings(EVIDENCE_PROVIDER="fixture")))

    response = client.post("/verify", json={"claim": "The Earth revolves around the Sun"})

    assert response.status_code == 200
    body = response.json()
    assert body["verdict"] == "REAL"
    assert 0 <= body["confidence"] <= 1
    assert body["summary"] and body["findings"] and body["sources"]


def test_google_provider_results_map_through_verify_contract():
    observed = {}

    def handler(request):
        observed["path"] = request.url.path
        observed["query"] = request.url.params.get("query")
        return httpx.Response(200, json={
            "claims": [{
                "text": "Drinking bleach cures viral infections",
                "claimReview": [{
                    "publisher": {"name": "FactCheck.org", "site": "factcheck.org"},
                    "url": "https://www.factcheck.org/bleach-check",
                    "title": "Fact check: bleach does not cure infections",
                    "textualRating": "False",
                }],
            }],
        })

    upstream = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    provider = GoogleFactCheckProvider("test-key", client=upstream, backoff_s=0)
    client = _LifespanClient(create_app(
        settings=_settings(), evidence_providers=[provider]
    ))

    response = client.post("/verify", json={
        "claim": "Drinking bleach cures viral infections"
    })

    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"verdict", "confidence", "summary", "findings", "sources"}
    assert body["verdict"] == "FAKE"
    assert body["sources"][0]["url"] == "https://www.factcheck.org/bleach-check"
    assert observed == {
        "path": "/v1alpha1/claims:search",
        "query": "Drinking bleach cures viral infections",
    }


def test_verify_rejects_blank_and_oversized_claims_with_422():
    client = _LifespanClient(create_app(settings=_settings(EVIDENCE_PROVIDER="fixture")))

    assert client.post("/verify", json={"claim": "   "}).status_code == 422
    assert client.post("/verify", json={"claim": "x" * 5001}).status_code == 422


def test_missing_google_configuration_returns_sanitized_503():
    client = _LifespanClient(create_app(settings=_settings()))

    response = client.post("/verify", json={"claim": "A claim to verify"})

    assert response.status_code == 503
    assert response.json() == {
        "detail": "Verification is temporarily unavailable. Please try again."
    }
    assert "FACTCHECK_API_KEY" not in response.text
    assert "factchecktools.googleapis.com" not in response.text


def test_conflicting_fact_checks_remain_uncertain():
    client = _LifespanClient(create_app(settings=_settings(EVIDENCE_PROVIDER="fixture")))

    response = client.post("/verify", json={"claim": "Coffee prevents all forms of cancer"})

    assert response.status_code == 200
    assert response.json()["verdict"] == "UNCERTAIN"


def test_configured_tfidf_artifact_loads_and_returns_a_valid_internal_prediction():
    settings = _settings(ML_PROVIDER="tfidf", EVIDENCE_PROVIDER="fixture")
    classifier = TfidfClassifier(settings.ml_model_path)
    logistic_regression = classifier._pipeline.named_steps["logisticregression"]

    assert set(logistic_regression.classes_) == {label.value for label in MLLabel}

    result = classifier.classify("The Earth revolves around the Sun")

    assert result.label in {MLLabel.REAL, MLLabel.FAKE, MLLabel.UNCERTAIN}
    assert math.isfinite(result.confidence)
    assert 0 <= result.confidence <= 1
    assert result.scores is not None
    assert set(result.scores) == set(MLLabel)
    assert not result.is_mock


def test_tfidf_artifact_missing_a_truwave_class_fails_validation(tmp_path):
    invalid_artifact = {
        "pipeline": SimpleNamespace(
            named_steps={
                "logisticregression": SimpleNamespace(classes_=["FAKE", "REAL"]),
            },
        ),
    }
    artifact_path = tmp_path / "missing-class.joblib"
    joblib.dump(invalid_artifact, artifact_path)

    with pytest.raises(MLUnavailableError, match="all expected TruWave labels"):
        TfidfClassifier(artifact_path)


def test_real_tfidf_artifact_is_configured_for_verify_with_fixture_evidence():
    settings = _settings(ML_PROVIDER="tfidf", EVIDENCE_PROVIDER="fixture")
    application = create_app(settings=settings)

    async def post_claim():
        async with application.router.lifespan_context(application):
            assert isinstance(application.state.verifier._ml, TfidfClassifier)
            async with httpx.AsyncClient(
                transport=httpx.ASGITransport(app=application),
                base_url="http://test",
            ) as client:
                return await client.post(
                    "/verify", json={"claim": "A claim without fixture evidence"}
                )

    response = asyncio.run(post_claim())

    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"verdict", "confidence", "summary", "findings", "sources"}
    assert body["verdict"] in {"REAL", "FAKE", "UNCERTAIN"}
    assert math.isfinite(body["confidence"])
    assert 0 <= body["confidence"] <= 1
    assert body["sources"] == []


def test_configured_tfidf_is_selected_and_invoked_by_verify(monkeypatch):
    calls = []

    class RecordingClassifier:
        def classify(self, claim):
            calls.append(claim)
            return MLResult(MLLabel.UNCERTAIN, 0.5, "tfidf-test/v1")

    monkeypatch.setattr("backend.main.TfidfClassifier", lambda _path: RecordingClassifier())
    application = create_app(settings=_settings(
        ML_PROVIDER="tfidf", EVIDENCE_PROVIDER="fixture"
    ))

    async def post_claim():
        async with application.router.lifespan_context(application):
            async with httpx.AsyncClient(
                transport=httpx.ASGITransport(app=application),
                base_url="http://test",
            ) as client:
                return await client.post(
                    "/verify", json={"claim": "A model execution check"}
                )

    response = asyncio.run(post_claim())

    assert response.status_code == 200
    assert response.json()["verdict"] == "UNCERTAIN"
    assert calls == ["TruWave startup warmup", "A model execution check"]


def test_unavailable_tfidf_artifact_fails_explicitly_without_mock_fallback(tmp_path):
    settings = replace(
        _settings(ML_PROVIDER="tfidf", EVIDENCE_PROVIDER="fixture"),
        ml_model_path=tmp_path / "missing-model.joblib",
    )

    with pytest.raises(ConfigError, match="TF-IDF ML model is unavailable"):
        build_verifier(settings)


def test_unavailable_tfidf_artifact_fails_during_app_startup(tmp_path):
    settings = replace(
        _settings(ML_PROVIDER="tfidf", EVIDENCE_PROVIDER="fixture"),
        ml_model_path=tmp_path / "missing-model.joblib",
    )
    application = create_app(settings=settings)

    async def start():
        async with application.router.lifespan_context(application):
            pass

    with pytest.raises(ConfigError, match="TF-IDF ML model is unavailable"):
        asyncio.run(start())


class RelatedFalseProvider:
    name = "related_test"

    async def search(self, claim):
        return [EvidenceItem(
            provider=self.name,
            publisher_name="Fact-check source",
            publisher_site="factcheck.org",
            title="Related disinfectant claim",
            url="https://factcheck.org/related",
            stance=Stance.REFUTES,
            raw_rating="False",
            reviewed_claim="MMS chlorine dioxide can prevent coronavirus",
            tier=SourceTier.KNOWN,
        )]


def test_related_evidence_is_returned_as_context_but_cannot_establish_verdict():
    client = _LifespanClient(create_app(
        settings=_settings(), evidence_providers=[RelatedFalseProvider()]
    ))

    response = client.post("/verify", json={"claim": "Drinking bleach cures COVID-19"})

    assert response.status_code == 200
    body = response.json()
    assert body["verdict"] == "UNCERTAIN"
    assert body["sources"][0]["url"] == "https://factcheck.org/related"
    assert any("related context" in finding for finding in body["findings"])


class FailingEvidenceProvider:
    name = "failure_test"

    async def search(self, claim):
        raise ProviderAuthError("private API_KEY_INVALID SECRET_VALUE")


def test_google_style_evidence_failure_is_sanitized_503():
    client = _LifespanClient(create_app(
        settings=_settings(), evidence_providers=[FailingEvidenceProvider()]
    ))

    response = client.post("/verify", json={"claim": "A claim to verify"})

    assert response.status_code == 503
    assert response.json() == {
        "detail": "Verification is temporarily unavailable. Please try again."
    }
    assert "SECRET_VALUE" not in response.text
    assert "API_KEY_INVALID" not in response.text
