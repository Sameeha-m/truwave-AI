"""EvidenceService: runs every provider, then filters, dedupes and ranks the results.

Providers raise; this service converts failures into ProviderReports so the
orchestrator can distinguish "found nothing" (empty) from "could not look"
(unavailable) and can still use partial results.
"""
from __future__ import annotations

import asyncio
import logging
import time
from dataclasses import replace
from datetime import date, datetime, timezone
from typing import Sequence

from .base import (
    EvidenceItem,
    EvidenceProvider,
    EvidenceResult,
    ProviderError,
    ProviderReport,
    RelevanceTier,
    SourceTier,
)
from .normalize import dedupe, relevance_tier

logger = logging.getLogger("truwave.evidence")


class EvidenceService:
    def __init__(
        self,
        providers: Sequence[EvidenceProvider],
        *,
        min_relevance: float = 0.5,
        max_items: int = 10,
        provider_timeout_s: float = 8.0,
    ) -> None:
        if not providers:
            raise ValueError("EvidenceService needs at least one provider")
        self._providers = list(providers)
        self._min_relevance = min_relevance
        self._max_items = max_items
        self._timeout_s = provider_timeout_s

    async def gather(self, claim: str) -> EvidenceResult:
        outcomes = await asyncio.gather(*(self._run_one(p, claim) for p in self._providers))

        scored: list[tuple[str, EvidenceItem]] = []
        reports: dict[str, ProviderReport] = {}
        for name, items, report in outcomes:
            reports[name] = report
            for item in items:
                tier, score = relevance_tier(claim, item.reviewed_claim)
                scored.append((name, replace(item, relevance=score, relevance_tier=tier)))

        relevant = [
            (n, i) for n, i in scored
            if (i.relevance_tier == RelevanceTier.DIRECT and i.relevance >= self._min_relevance)
            or i.relevance_tier == RelevanceTier.RELATED
        ]
        relevant.sort(key=lambda pair: _rank_key(pair[1]))
        # Deduplicate across providers, remembering which provider each survivor came from.
        survivors = dedupe([i for _, i in relevant])[: self._max_items]
        survivor_ids = {id(i) for i in survivors}
        kept_by_provider: dict[str, int] = {}
        for name, item in relevant:
            if id(item) in survivor_ids:
                kept_by_provider[name] = kept_by_provider.get(name, 0) + 1

        final_reports = []
        for name, report in reports.items():
            if report.status == "failed":
                final_reports.append(report)
                continue
            kept = kept_by_provider.get(name, 0)
            final_reports.append(replace(report, kept_count=kept, status="ok" if kept else "empty"))

        return EvidenceResult(
            items=survivors,
            reports=final_reports,
            retrieved_at=datetime.now(timezone.utc),
        )

    async def _run_one(
        self, provider: EvidenceProvider, claim: str
    ) -> tuple[str, list[EvidenceItem], ProviderReport]:
        started = time.monotonic()
        name = provider.name

        def elapsed() -> int:
            return int((time.monotonic() - started) * 1000)

        try:
            items = await asyncio.wait_for(provider.search(claim), timeout=self._timeout_s)
        except asyncio.TimeoutError:
            logger.warning("evidence provider %s timed out", name)
            return name, [], ProviderReport(name, "failed", "timeout", latency_ms=elapsed())
        except ProviderError as exc:
            logger.warning("evidence provider %s failed: %s", name, exc.code)
            return name, [], ProviderReport(name, "failed", exc.code, latency_ms=elapsed())
        except Exception as exc:  # a buggy provider must not take the request down
            # Log only the exception type: arbitrary exception text could contain secrets.
            logger.error("evidence provider %s crashed: %s", name, type(exc).__name__)
            return name, [], ProviderReport(name, "failed", "unexpected", latency_ms=elapsed())

        report = ProviderReport(name, "ok" if items else "empty", raw_count=len(items), latency_ms=elapsed())
        return name, list(items), report


def _rank_key(item: EvidenceItem) -> tuple:
    # KNOWN publishers first, then higher relevance, then newer reviews.
    tier_rank = 0 if item.tier == SourceTier.KNOWN else 1
    newest_first = -(item.review_date or date.min).toordinal()
    return (tier_rank, -item.relevance, newest_first)
