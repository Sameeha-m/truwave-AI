"""Verification engine tests: the R1-R9 rule table, run end to end through
Verifier -> EvidenceService -> FixtureEvidenceProvider (no network)."""
import time

import pytest

from backend.verifier import Decision, Verdict, VerificationUnavailable, Verifier, assess_evidence, decide
from evidence.base import EvidenceItem, EvidenceResult, ProviderReport, SourceTier, Stance
from evidence.fixture import FixtureEvidenceProvider
from evidence.normalize import normalize_rating
from evidence.service import EvidenceService
from ml.base import MLLabel, MLResult
from tests.helpers import run

BLEACH = "Drinking bleach cures viral infections"                 # refuted, 2 publishers
EARTH = "The Earth revolves around the Sun"                        # supported, 2 publishers
UNDERWATER = "Humans can breathe normally underwater without equipment"  # refuted, 1 known publisher
COFFEE = "Coffee prevents all forms of cancer"                     # conflicting
VITAMIN = "Vitamin C cures the common cold"                        # mixed only
STREAMING = "A new tax on streaming subscriptions starts next month"      # 1 unknown publisher
NOTHING = "A claim that no fact-checker has ever reviewed"
ERROR = "Fixture claim that triggers a provider error"


class StubML:
    def __init__(self, label=MLLabel.FAKE, confidence=0.9, *, is_mock=False, error=None, delay=0.0):
        self.label, self.confidence, self.is_mock, self.error, self.delay = label, confidence, is_mock, error, delay
        self.calls = []

    def classify(self, claim):
        self.calls.append(claim)
        if self.delay:
            time.sleep(self.delay)
        if self.error:
            raise self.error
        return MLResult(self.label, self.confidence, "stub/v1", is_mock=self.is_mock)


def verify(claim, ml, **kw):
    service = EvidenceService([FixtureEvidenceProvider()])
    return run(Verifier(ml, service, **kw).verify(claim))


FAKE = lambda c=0.9, **k: StubML(MLLabel.FAKE, c, **k)
REAL = lambda c=0.9, **k: StubML(MLLabel.REAL, c, **k)
UNSURE = lambda c=0.6, **k: StubML(MLLabel.UNCERTAIN, c, **k)


# ------------------------------------------------------------------ rule matrix
@pytest.mark.parametrize("claim,ml,verdict,rule,conf", [
    # Case A / D: ML agrees with strong multi-publisher evidence
    (BLEACH, FAKE(0.94), Verdict.FAKE, "R1_AGREE_MULTI", 0.90),
    (EARTH, REAL(0.92), Verdict.REAL, "R1_AGREE_MULTI", 0.90),
    (UNDERWATER, FAKE(0.9), Verdict.FAKE, "R2_AGREE_SINGLE", 0.80),
    # ML neutral: UNCERTAIN label, weak score, or missing
    (BLEACH, UNSURE(), Verdict.FAKE, "R3_EVIDENCE_MULTI", 0.80),
    (BLEACH, FAKE(0.55), Verdict.FAKE, "R3_EVIDENCE_MULTI", 0.80),
    (BLEACH, None, Verdict.FAKE, "R3_EVIDENCE_MULTI", 0.80),
    (UNDERWATER, None, Verdict.FAKE, "R4_EVIDENCE_SINGLE", 0.70),
    # Case C / E: ML strongly opposes the evidence
    (BLEACH, REAL(0.9), Verdict.FAKE, "R5_DISAGREE_MULTI", 0.65),
    (EARTH, FAKE(0.9), Verdict.REAL, "R5_DISAGREE_MULTI", 0.65),
    (UNDERWATER, REAL(0.9), Verdict.UNCERTAIN, "R6_DISAGREE_SINGLE", 0.50),
    # Conflicting / partly-true fact-checks: ML cannot break the tie
    (COFFEE, FAKE(0.99), Verdict.UNCERTAIN, "R7_CONFLICT", 0.60),
    (COFFEE, None, Verdict.UNCERTAIN, "R7_CONFLICT", 0.60),
    (VITAMIN, REAL(0.99), Verdict.UNCERTAIN, "R7_CONFLICT", 0.60),
    # Case B: ML alone never decides
    (NOTHING, FAKE(0.99), Verdict.UNCERTAIN, "R8_NONE", 0.50),
    (NOTHING, REAL(0.99), Verdict.UNCERTAIN, "R8_NONE", 0.50),
    ("Fixture claim with unrelated results", FAKE(0.99), Verdict.UNCERTAIN, "R8_NONE", 0.50),
    # Only one publisher we cannot vouch for
    (STREAMING, FAKE(0.99), Verdict.UNCERTAIN, "R8_WEAK", 0.50),
])
def test_rule_table(claim, ml, verdict, rule, conf):
    d = verify(claim, ml)
    assert (d.verdict, d.rule_id, d.confidence) == (verdict, rule, conf)


def test_case_f_evidence_down_is_unavailable_not_uncertain():
    with pytest.raises(VerificationUnavailable):
        verify(ERROR, FAKE(0.99))


def test_case_h_both_fail_is_unavailable():
    with pytest.raises(VerificationUnavailable):
        verify(ERROR, StubML(error=RuntimeError("model crashed")))


def test_case_g_ml_down_but_evidence_strong_still_decides():
    d = verify(BLEACH, StubML(error=RuntimeError("model crashed")))
    assert (d.verdict, d.rule_id) == (Verdict.FAKE, "R3_EVIDENCE_MULTI")
    assert d.degraded_reasons == ["ml_unavailable"]


def test_ml_down_and_no_evidence_is_a_genuine_uncertain():
    d = verify(NOTHING, StubML(error=RuntimeError("x")))
    assert d.verdict == Verdict.UNCERTAIN and d.degraded_reasons == ["ml_unavailable"]


def test_ml_timeout_degrades_instead_of_failing():
    d = verify(BLEACH, FAKE(delay=0.4), ml_timeout_s=0.05)
    assert d.verdict == Verdict.FAKE and d.degraded_reasons == ["ml_timeout"]


def test_ml_not_configured_is_noted_but_works():
    d = verify(BLEACH, None)
    assert d.degraded_reasons == ["ml_not_configured"] and d.verdict == Verdict.FAKE


# ------------------------------------------------------------------ properties
def test_raw_ml_score_never_changes_public_confidence():
    assert verify(BLEACH, FAKE(0.81)).confidence == verify(BLEACH, FAKE(0.99)).confidence


def test_ml_threshold_is_configurable():
    assert verify(BLEACH, FAKE(0.75), ml_threshold=0.70).rule_id == "R1_AGREE_MULTI"
    assert verify(BLEACH, FAKE(0.75), ml_threshold=0.80).rule_id == "R3_EVIDENCE_MULTI"


@pytest.mark.parametrize("claim", [BLEACH, EARTH, UNDERWATER, COFFEE, VITAMIN, STREAMING, NOTHING])
@pytest.mark.parametrize("ml", [None, FAKE(), REAL(), UNSURE()])
def test_every_decision_is_well_formed(claim, ml):
    d = verify(claim, ml)
    assert isinstance(d, Decision)
    assert 0.0 <= d.confidence <= 0.95            # never claims certainty
    assert d.summary.strip() and d.findings and all(f.strip() for f in d.findings)
    assert all(s.name and s.title and s.url.startswith("http") for s in d.sources)  # Flutter needs non-null strings
    assert len({s.url for s in d.sources}) == len(d.sources)


def test_summary_and_findings_never_leak_internals():
    for ml in (FAKE(0.9137), REAL(0.9137)):
        d = verify(BLEACH, ml)
        text = " ".join([d.summary, *d.findings]).lower()
        for banned in ("0.91", "91%", "distilbert", "probab", "stub", "model", "rule", "r1_", "traceback"):
            assert banned not in text


def test_max_sources_cap():
    assert len(verify(BLEACH, FAKE(), max_sources=1).sources) == 1


def test_real_ml_is_credited_on_agreement_but_mock_is_not():
    credited = verify(BLEACH, FAKE(0.9, is_mock=False))
    mocked = verify(BLEACH, FAKE(0.9, is_mock=True))
    assert any("Automated text analysis" in f for f in credited.findings)
    assert not any("automated" in f.lower() for f in mocked.findings)
    assert (credited.verdict, credited.confidence) == (mocked.verdict, mocked.confidence)  # same engine path


def test_empty_claim_rejected_and_claim_is_stripped_before_ml():
    ml = FAKE()
    with pytest.raises(ValueError):
        verify("   ", ml)
    verify(f"  {BLEACH}  ", ml)
    assert ml.calls == [BLEACH]


# ------------------------------------------------------------------ evidence assessment unit tests
def _it(site, rating, tier=SourceTier.UNKNOWN, url=None):
    return EvidenceItem("t", site, site, "t " + site, url or f"https://{site}/x", normalize_rating(rating), rating, "c", tier, 1.0)


def _ev(*items, partial=False):
    reports = [ProviderReport("p", "ok", kept_count=len(items))]
    if partial:
        reports.append(ProviderReport("q", "failed", "timeout"))
    from datetime import datetime, timezone
    return EvidenceResult(list(items), reports, datetime.now(timezone.utc))


def test_two_unknown_publishers_are_enough_but_one_is_not():
    assert assess_evidence(_ev(_it("a.example", "False"), _it("b.example", "False"))).state == "REFUTED"
    assert assess_evidence(_ev(_it("a.example", "False"))).state == "WEAK"
    # the same publisher twice is still one publisher
    assert assess_evidence(_ev(_it("a.example", "False", url="https://a.example/1"),
                               _it("a.example", "False", url="https://a.example/2"))).state == "WEAK"


def test_mixed_ratings_that_outweigh_the_verdict_conflict():
    ev = _ev(_it("a.example", "False", SourceTier.KNOWN), _it("b.example", "Half True"), _it("c.example", "Misleading"))
    assert assess_evidence(ev).state == "CONFLICTING"


def test_only_unrated_items_count_as_no_evidence():
    assert assess_evidence(_ev(_it("a.example", "Satire"), _it("b.example", "Falsch"))).state == "NONE"


def test_partial_evidence_failure_is_recorded():
    d = decide(None, _ev(_it("a.example", "False", SourceTier.KNOWN), _it("b.example", "False"), partial=True))
    assert d.verdict == Verdict.FAKE and "evidence_partial" in d.degraded_reasons
