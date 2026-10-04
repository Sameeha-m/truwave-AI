"""Fixture evidence provider: canned data for tests, offline development and demos.

NOT a substitute for GoogleFactCheckProvider. It implements the same
EvidenceProvider interface, so its items still go through EvidenceService
(relevance gate, dedupe) and the verification engine exactly like real ones.
"""
from __future__ import annotations

import asyncio
import json
from pathlib import Path
from typing import Any, Mapping

from .base import (
    EvidenceItem,
    ProviderBadResponse,
    ProviderError,
    ProviderRateLimited,
    ProviderTimeout,
    SourceTier,
)
from .normalize import claim_key, normalize_rating, publisher_tier

FIXTURES_FILE = Path(__file__).with_name("fixtures.json")


def load_fixtures(path: Path = FIXTURES_FILE) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8")).get("claims", {})


class FixtureEvidenceProvider:
    name = "fixture"

    def __init__(self, scenarios: Mapping[str, Any] | None = None) -> None:
        raw = load_fixtures() if scenarios is None else scenarios
        self._scenarios = {claim_key(k): v for k, v in raw.items()}

    async def search(self, claim: str) -> list[EvidenceItem]:
        scenario = self._scenarios.get(claim_key(claim))
        if scenario is None:
            return []  # unknown claim: behaves like "nothing found"

        behavior = scenario.get("behavior")
        if behavior == "error":
            raise ProviderError("fixture: simulated provider failure")
        if behavior == "timeout":
            raise ProviderTimeout("fixture: simulated timeout")
        if behavior == "rate_limited":
            raise ProviderRateLimited("fixture: simulated rate limit")
        if behavior == "bad_response":
            raise ProviderBadResponse("fixture: simulated malformed response")
        if behavior == "slow":
            await asyncio.sleep(float(scenario.get("delay_ms", 1000)) / 1000.0)

        return [self._build_item(entry, claim) for entry in scenario.get("items", [])]

    def _build_item(self, entry: Mapping[str, Any], claim: str) -> EvidenceItem:
        site = entry.get("publisher_site", "")
        tier = SourceTier(entry["tier"]) if "tier" in entry else publisher_tier(site)
        rating = entry.get("raw_rating", "")
        return EvidenceItem(
            provider=self.name,
            publisher_name=entry.get("publisher_name", "Fixture publisher"),
            publisher_site=site,
            title=entry.get("title", ""),
            url=entry.get("url", ""),
            stance=normalize_rating(rating),
            raw_rating=rating,
            reviewed_claim=entry.get("reviewed_claim", claim),
            tier=tier,
        )
