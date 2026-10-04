import asyncio

import pytest

from evidence.base import (
    EvidenceItem, ProviderBadResponse, ProviderError, ProviderTimeout, RelevanceTier, SourceTier, Stance,
)
from evidence.fixture import FixtureEvidenceProvider
from evidence.service import EvidenceService
from backend.verifier import Verdict, decide
from tests.helpers import run


def gather(claim, *providers, **kw):
    return run(EvidenceService(list(providers), **kw).gather(claim))


class Static:
    def __init__(self, name, items=None, error=None, delay=0):
        self.name, self._items, self._error, self._delay = name, items or [], error, delay

    async def search(self, claim):
        if self._delay:
            await asyncio.sleep(self._delay)
        if self._error:
            raise self._error
        return self._items


def item(url, rating="False", reviewed="Drinking bleach cures viral infections", site="a.example", name="A",
         tier=SourceTier.UNKNOWN, title="T"):
    from evidence.normalize import normalize_rating
    return EvidenceItem("static", name, site, title, url, normalize_rating(rating), rating, reviewed, tier)


CLAIM = "Drinking bleach cures viral infections"


# ------------------------------------------------------------- fixture provider through the service
def test_supporting_evidence():
    r = gather("The Earth revolves around the Sun", FixtureEvidenceProvider())
    assert r.status == "ok"
    assert {i.stance for i in r.items} == {Stance.SUPPORTS}
    assert all(i.relevance >= 0.5 for i in r.items)


def test_refuting_evidence():
    r = gather(CLAIM, FixtureEvidenceProvider())
    assert r.status == "ok" and {i.stance for i in r.items} == {Stance.REFUTES}
    assert len(r.items) == 2


def test_conflicting_evidence_is_preserved():
    r = gather("Coffee prevents all forms of cancer", FixtureEvidenceProvider())
    assert {i.stance for i in r.items} == {Stance.REFUTES, Stance.SUPPORTS}


def test_no_evidence_is_empty_not_unavailable():
    r = gather("Something nobody ever fact-checked", FixtureEvidenceProvider())
    assert r.status == "empty" and r.items == [] and not r.partial
    assert r.reports[0].status == "empty"


def test_irrelevant_results_are_dropped_by_the_relevance_gate():
    r = gather("Fixture claim with unrelated results", FixtureEvidenceProvider())
    assert r.status == "empty"
    assert r.reports[0].raw_count == 1 and r.reports[0].kept_count == 0


@pytest.mark.parametrize("claim,code", [
    ("Fixture claim that triggers a provider error", "unavailable"),
    ("Fixture claim that triggers a timeout", "timeout"),
    ("Fixture claim that triggers a rate limit", "rate_limited"),
    ("Fixture claim that triggers a malformed response", "bad_response"),
])
def test_provider_failures_become_unavailable(claim, code):
    r = gather(claim, FixtureEvidenceProvider())
    assert r.status == "unavailable"
    assert r.reports[0].status == "failed" and r.reports[0].error_code == code


def test_unknown_fixture_claim_matches_ignoring_case_and_punctuation():
    r = gather("  the EARTH revolves around the sun!! ", FixtureEvidenceProvider())
    assert r.status == "ok"


def test_every_fixture_publisher_is_clearly_labelled_fake():
    from evidence.fixture import load_fixtures
    for scenario in load_fixtures().values():
        for entry in scenario.get("items", []):
            assert "fixture" in entry["publisher_name"].lower()
            assert entry["url"].startswith("https://") and ".example/" in entry["url"]


# ------------------------------------------------------------- service behaviour
def test_duplicates_across_providers_are_removed_and_best_copy_kept():
    a = Static("one", [item("https://x.example/a?utm_source=z", tier=SourceTier.UNKNOWN)])
    b = Static("two", [item("https://www.x.example/a", tier=SourceTier.KNOWN)])
    r = gather(CLAIM, a, b)
    assert len(r.items) == 1 and r.items[0].tier == SourceTier.KNOWN  # KNOWN ranks first, so it survives


def test_partial_failure_keeps_results_and_flags_partial():
    good = Static("good", [item("https://x.example/a")])
    bad = Static("bad", error=ProviderError("boom"))
    r = gather(CLAIM, good, bad)
    assert r.status == "ok" and r.partial
    assert {rep.provider: rep.status for rep in r.reports} == {"good": "ok", "bad": "failed"}


def test_all_providers_failing_is_unavailable():
    r = gather(CLAIM, Static("a", error=ProviderTimeout()), Static("b", error=ProviderBadResponse()))
    assert r.status == "unavailable" and not r.partial


def test_slow_provider_times_out_without_blocking_forever():
    r = gather(CLAIM, Static("slow", [item("https://x.example/a")], delay=1.0), provider_timeout_s=0.05)
    assert r.status == "unavailable" and r.reports[0].error_code == "timeout"


def test_unexpected_crash_is_contained_and_not_leaked():
    r = gather(CLAIM, Static("buggy", error=RuntimeError("secret AIza123 inside")))
    assert r.status == "unavailable"
    assert r.reports[0].error_code == "unexpected"
    assert "AIza" not in repr(r.reports)


def test_ranking_prefers_known_publishers_then_relevance():
    weak_known = item("https://k.example/a", reviewed="drinking bleach cures viral infections today", tier=SourceTier.KNOWN, site="k.example", name="K", title="K")
    strong_unknown = item("https://u.example/a", reviewed=CLAIM, tier=SourceTier.UNKNOWN, site="u.example", name="U", title="U")
    r = gather(CLAIM, Static("p", [strong_unknown, weak_known]))
    assert [i.tier for i in r.items] == [SourceTier.KNOWN, SourceTier.UNKNOWN]


def test_max_items_cap():
    many = [item(f"https://x.example/{n}", title=f"T{n}") for n in range(8)]
    assert len(gather(CLAIM, Static("p", many), max_items=3).items) == 3


def test_service_requires_a_provider():
    with pytest.raises(ValueError):
        EvidenceService([])


def test_bleach_covid_reviews_are_related_context_not_direct_matches():
    claim = "Drinking bleach cures COVID-19"
    items = [
        item("https://factcheck.org/mms", reviewed=
             "MMS chlorine dioxide can be effective in preventing and eradicating coronavirus",
             site="factcheck.org", name="FactCheck.org", title="MMS claim"),
        item("https://snopes.com/injection", reviewed=
             "Donald Trump suggested people inject bleach or other disinfectants to treat COVID-19",
             site="snopes.com", name="Snopes", title="Trump disinfectant claim"),
    ]
    result = gather(claim, Static("google_factcheck", items))
    assert len(result.items) == 2
    assert all(i.relevance_tier == RelevanceTier.RELATED for i in result.items)
    decision = decide(None, result)
    assert decision.verdict == Verdict.UNCERTAIN
