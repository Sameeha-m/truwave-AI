"""Verification engine + orchestrator.

    ML prediction + Evidence  ->  decide()  ->  Decision (final verdict)

`decide` is a pure, deterministic rule table (R1-R9). Evidence is the primary basis
for a REAL/FAKE verdict. The ML prediction can corroborate (raising confidence),
stay neutral, or oppose (lowering confidence / forcing UNCERTAIN) - but it never
produces REAL/FAKE on its own. Confidence values are fixed tiers per rule, NOT
probabilities, and the raw ML score never reaches the public result.
"""
from __future__ import annotations

import asyncio
import logging
from dataclasses import dataclass, field
from enum import Enum

from evidence.base import EvidenceItem, EvidenceResult, Stance, SourceTier
from evidence.normalize import publisher_identity
from evidence.service import EvidenceService
from ml.base import MLClassifier, MLLabel, MLResult

logger = logging.getLogger("truwave.verifier")


class Verdict(str, Enum):
    REAL = "REAL"
    FAKE = "FAKE"
    UNCERTAIN = "UNCERTAIN"


@dataclass(frozen=True)
class SourceRef:
    name: str
    title: str
    url: str


@dataclass(frozen=True)
class Decision:
    verdict: Verdict
    confidence: float
    summary: str
    findings: list[str]
    sources: list[SourceRef]
    rule_id: str                                  # internal: for logs/tests, never sent to Flutter
    ml: MLResult | None = None                    # internal
    evidence: EvidenceResult | None = None        # internal
    degraded_reasons: list[str] = field(default_factory=list)


class VerificationUnavailable(Exception):
    """No verdict can be given right now (rule R9). Maps to HTTP 503 in the API layer.

    Deliberately NOT turned into UNCERTAIN: UNCERTAIN is a real outcome, and an
    outage must not be saved to the user's history as one.
    """

    retryable = True


# Fixed confidence tiers (heuristic, not probabilities).
CONFIDENCE = {
    "R1": 0.90,  # evidence from >=2 publishers, ML agrees
    "R2": 0.80,  # evidence from 1 known publisher, ML agrees
    "R3": 0.80,  # evidence from >=2 publishers, ML neutral/unavailable
    "R4": 0.70,  # evidence from 1 known publisher, ML neutral/unavailable
    "R5": 0.65,  # evidence from >=2 publishers, ML opposes
    "R6": 0.50,  # 1 publisher only, ML opposes -> UNCERTAIN
    "R7": 0.60,  # fact-checkers conflict / only partly true -> UNCERTAIN
    "R8": 0.50,  # nothing usable found, or only weak evidence -> UNCERTAIN
}


# ---------------------------------------------------------------- assessment
@dataclass(frozen=True)
class EvidenceAssessment:
    state: str                       # REFUTED | SUPPORTED | CONFLICTING | WEAK | NONE
    direction: Verdict | None        # FAKE for REFUTED, REAL for SUPPORTED
    multi: bool                      # >=2 distinct publishers back the decisive stance
    decisive: list[EvidenceItem]
    others: list[EvidenceItem]


def assess_evidence(evidence: EvidenceResult) -> EvidenceAssessment:
    rated = [i for i in evidence.items if i.stance != Stance.UNRATED]
    refutes = [i for i in rated if i.stance == Stance.REFUTES]
    supports = [i for i in rated if i.stance == Stance.SUPPORTS]
    mixed = [i for i in rated if i.stance == Stance.MIXED]

    if not rated:
        return EvidenceAssessment("NONE", None, False, [], list(evidence.items))
    if (refutes and supports) or (not refutes and not supports):
        return EvidenceAssessment("CONFLICTING", None, False, [], rated)

    decisive, direction, state = (
        (refutes, Verdict.FAKE, "REFUTED") if refutes else (supports, Verdict.REAL, "SUPPORTED")
    )
    if len(mixed) >= len(decisive):  # qualified/partly-true ratings outweigh the verdict
        return EvidenceAssessment("CONFLICTING", None, False, [], rated)

    publishers = {publisher_identity(i) for i in decisive}
    multi = len(publishers) >= 2
    any_known = any(i.tier == SourceTier.KNOWN for i in decisive)
    others = [i for i in evidence.items if i not in decisive]
    if not multi and not any_known:
        return EvidenceAssessment("WEAK", direction, False, decisive, others)
    return EvidenceAssessment(state, direction, multi, decisive, others)


def ml_stance(ml: MLResult | None, threshold: float) -> Verdict | None:
    """The ML prediction's direction, or None if it is neutral (missing/UNCERTAIN/weak)."""
    if ml is None or ml.label == MLLabel.UNCERTAIN or ml.confidence < threshold:
        return None
    return Verdict.REAL if ml.label == MLLabel.REAL else Verdict.FAKE


# ---------------------------------------------------------------- wording
def _finding(item: EvidenceItem) -> str:
    if item.raw_rating:
        return f"{item.publisher_name} rated a matching claim “{item.raw_rating}”."
    return f"{item.publisher_name} published a fact-check of a matching claim."


def _sources(first: list[EvidenceItem], rest: list[EvidenceItem], cap: int) -> list[SourceRef]:
    ordered: list[EvidenceItem] = []
    seen: set[str] = set()
    for item in [*first, *rest]:
        if item.url not in seen:
            seen.add(item.url)
            ordered.append(item)
    return [SourceRef(i.publisher_name, i.title, i.url) for i in ordered[:cap]]


def _word(direction: Verdict) -> str:
    return "false" if direction == Verdict.FAKE else "true"


# ---------------------------------------------------------------- decision
def decide(
    ml: MLResult | None,
    evidence: EvidenceResult,
    *,
    ml_threshold: float = 0.80,
    max_sources: int = 5,
    degraded_reasons: list[str] | None = None,
) -> Decision:
    degraded = list(degraded_reasons or [])

    def build(verdict, rule, summary, findings, first, rest) -> Decision:
        return Decision(
            verdict=verdict,
            confidence=CONFIDENCE[rule[:2]],
            summary=summary,
            findings=findings or ["No further details are available."],
            sources=_sources(first, rest, max_sources),
            rule_id=rule,
            ml=ml,
            evidence=evidence,
            degraded_reasons=degraded,
        )

    # R9: we could not look at all.
    if evidence.status == "unavailable":
        raise VerificationUnavailable("evidence providers unavailable")
    if evidence.partial:
        degraded.append("evidence_partial")

    a = assess_evidence(evidence)
    all_findings = [_finding(i) for i in [*a.decisive, *a.others]][:max_sources]

    # R8: nothing usable, or only weak evidence.
    if a.state == "NONE":
        findings = all_findings or ["No matching fact-checks were found."]
        if all_findings:
            findings.append("None of them gave a clear true/false rating.")
        return build(
            Verdict.UNCERTAIN, "R8_NONE",
            "We couldn't find a fact-check that clearly rates this claim, so there isn't enough "
            "evidence to call it real or fake.",
            findings, [], a.others,
        )
    if a.state == "WEAK":
        return build(
            Verdict.UNCERTAIN, "R8_WEAK",
            "We found a fact-check, but only from a source we can't yet verify, so it isn't "
            "enough to call this real or fake.",
            all_findings, a.decisive, a.others,
        )

    # R7: fact-checkers disagree, or ratings are only partly true.
    if a.state == "CONFLICTING":
        return build(
            Verdict.UNCERTAIN, "R7_CONFLICT",
            "Fact-checkers disagree about this claim, or rate it as only partly true, so TruWave "
            "can't give a clear verdict.",
            all_findings, a.others, [],
        )

    # Evidence is decisive (REFUTED or SUPPORTED). Reconcile with the ML prediction.
    assert a.direction is not None
    direction = a.direction
    ml_dir = ml_stance(ml, ml_threshold)
    word = _word(direction)
    who = "Multiple independent fact-checkers" if a.multi else "A fact-checker we recognise"
    real_ml = ml is not None and not ml.is_mock   # never credit "automated analysis" to a mock

    if ml_dir == direction:
        rule = "R1_AGREE_MULTI" if a.multi else "R2_AGREE_SINGLE"
        findings = list(all_findings)
        if real_ml:
            findings.append("Automated text analysis, which is not a fact-check, leaned the same way.")
        return build(direction, rule, f"{who} rated this claim {word}.", findings, a.decisive, a.others)

    if ml_dir is None:
        rule = "R3_EVIDENCE_MULTI" if a.multi else "R4_EVIDENCE_SINGLE"
        return build(direction, rule, f"{who} rated this claim {word}.", all_findings, a.decisive, a.others)

    # ML opposes the evidence.
    if a.multi:
        return build(
            direction, "R5_DISAGREE_MULTI",
            f"{who} rated this claim {word}. We're less certain than usual because other signals "
            "pointed the other way.",
            all_findings, a.decisive, a.others,
        )
    return build(
        Verdict.UNCERTAIN, "R6_DISAGREE_SINGLE",
        "The signals about this claim conflict, and one fact-check isn't enough to settle it.",
        all_findings, a.decisive, a.others,
    )


# ---------------------------------------------------------------- orchestrator
class Verifier:
    """Runs ML and Evidence in parallel and hands both results to decide()."""

    def __init__(
        self,
        ml: MLClassifier | None,
        evidence: EvidenceService,
        *,
        ml_timeout_s: float = 5.0,
        ml_threshold: float = 0.80,
        max_sources: int = 5,
    ) -> None:
        self._ml = ml
        self._evidence = evidence
        self._ml_timeout_s = ml_timeout_s
        self._ml_threshold = ml_threshold
        self._max_sources = max_sources

    async def verify(self, claim: str) -> Decision:
        claim = claim.strip()
        if not claim:
            raise ValueError("claim must not be empty")

        ml_outcome, evidence = await asyncio.gather(self._run_ml(claim), self._evidence.gather(claim))
        ml_result, ml_problem = ml_outcome
        degraded = [ml_problem] if ml_problem else []

        decision = decide(
            ml_result, evidence,
            ml_threshold=self._ml_threshold,
            max_sources=self._max_sources,
            degraded_reasons=degraded,
        )
        logger.info(
            "verdict=%s rule=%s ml=%s degraded=%s",
            decision.verdict.value, decision.rule_id,
            ml_result.model_id if ml_result else None, decision.degraded_reasons,
        )
        return decision

    async def _run_ml(self, claim: str) -> tuple[MLResult | None, str | None]:
        if self._ml is None:
            return None, "ml_not_configured"
        try:
            result = await asyncio.wait_for(
                asyncio.to_thread(self._ml.classify, claim), timeout=self._ml_timeout_s
            )
            return result, None
        except asyncio.TimeoutError:
            logger.warning("ML classifier timed out")
            return None, "ml_timeout"
        except Exception as exc:  # any classifier failure degrades; it never breaks the request
            logger.warning("ML classifier failed: %s", type(exc).__name__)
            return None, "ml_unavailable"
