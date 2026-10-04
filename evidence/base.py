"""Evidence layer contracts. Nothing here imports from backend/ or ml/."""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime
from enum import Enum
from typing import Literal, Protocol


class Stance(str, Enum):
    SUPPORTS = "SUPPORTS"  # the fact-check says the claim is true
    REFUTES = "REFUTES"    # the fact-check says the claim is false
    MIXED = "MIXED"        # partly true / missing context / unproven / misleading
    UNRATED = "UNRATED"    # no usable rating (satire, unknown wording, other language)


class RelevanceTier(str, Enum):
    DIRECT = "DIRECT"       # may inform the verdict
    RELATED = "RELATED"     # context only; never proof of this claim
    UNRELATED = "UNRELATED" # discarded by EvidenceService


class SourceTier(str, Enum):
    KNOWN = "KNOWN"      # publisher is in evidence/publishers.json
    UNKNOWN = "UNKNOWN"


@dataclass(frozen=True)
class EvidenceItem:
    provider: str
    publisher_name: str
    publisher_site: str       # host-level, no "www." (e.g. "politifact.com")
    title: str
    url: str
    stance: Stance            # normalized from the free-text rating
    raw_rating: str           # publisher's own wording, e.g. "Mostly False" (internal)
    reviewed_claim: str       # the claim text the fact-checker actually reviewed
    tier: SourceTier
    relevance: float = 0.0    # 0..1 match to the user's claim; filled in by EvidenceService
    relevance_tier: RelevanceTier = RelevanceTier.DIRECT
    review_date: date | None = None
    snippet: str | None = None


ProviderStatus = Literal["ok", "empty", "failed"]


@dataclass(frozen=True)
class ProviderReport:
    provider: str
    status: ProviderStatus
    error_code: str | None = None
    raw_count: int = 0        # items the provider returned
    kept_count: int = 0       # items that survived the relevance gate + dedupe
    latency_ms: int = 0


@dataclass(frozen=True)
class EvidenceResult:
    items: list[EvidenceItem]          # relevant, deduplicated, best first
    reports: list[ProviderReport]
    retrieved_at: datetime

    @property
    def status(self) -> Literal["ok", "empty", "unavailable"]:
        """ok = relevant items found; empty = looked, found nothing; unavailable = could not look."""
        if self.reports and all(r.status == "failed" for r in self.reports):
            return "unavailable"
        return "ok" if self.items else "empty"

    @property
    def partial(self) -> bool:
        """True when some (but not all) providers failed."""
        failed = [r for r in self.reports if r.status == "failed"]
        return bool(failed) and len(failed) < len(self.reports)


class ProviderError(Exception):
    """A provider could not produce a result. `code` is a short, safe, stable string.

    Messages must never contain secrets, request URLs or raw upstream bodies.
    """

    code = "unavailable"

    def __init__(self, message: str = "", *, code: str | None = None, reason: str | None = None):
        super().__init__(message or (code or self.code))
        if code:
            self.code = code
        self.reason = reason  # optional machine-readable upstream reason, e.g. "API_KEY_INVALID"


class ProviderTimeout(ProviderError):
    code = "timeout"


class ProviderRateLimited(ProviderError):
    code = "rate_limited"


class ProviderAuthError(ProviderError):
    code = "auth_failed"


class ProviderNotConfigured(ProviderError):
    code = "no_api_key"


class ProviderBadResponse(ProviderError):
    code = "bad_response"


class EvidenceProvider(Protocol):
    """One source of fact-check evidence. Add a provider by implementing this."""

    name: str

    async def search(self, claim: str) -> list[EvidenceItem]:
        """Return parsed items (relevance unset). Raise ProviderError on failure."""
        ...
