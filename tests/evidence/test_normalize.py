import pytest

from evidence.base import EvidenceItem, SourceTier, Stance
from evidence.normalize import (
    canonical_url, claim_key, dedupe, normalize_rating, publisher_tier, relevance, site_root,
)


@pytest.mark.parametrize("raw,expected", [
    ("False", Stance.REFUTES), ("Pants on Fire", Stance.REFUTES), ("pants-fire", Stance.REFUTES),
    ("Mostly False", Stance.REFUTES), ("Not true", Stance.REFUTES), ("Fake", Stance.REFUTES),
    ("Debunked!", Stance.REFUTES),
    ("True", Stance.SUPPORTS), ("Mostly True", Stance.SUPPORTS), ("Correct", Stance.SUPPORTS),
    ("Accurate", Stance.SUPPORTS),
    ("Half True", Stance.MIXED), ("Partly false", Stance.MIXED), ("Missing context", Stance.MIXED),
    ("Misleading", Stance.MIXED), ("Unproven", Stance.MIXED), ("True but misleading", Stance.MIXED),
    ("Unverified", Stance.MIXED), ("Outdated", Stance.MIXED),
    ("Satire", Stance.UNRATED), ("Falsch", Stance.UNRATED), ("", Stance.UNRATED),
    ("   ", Stance.UNRATED), (None, Stance.UNRATED), ("Four stars", Stance.UNRATED),
])
def test_rating_normalization(raw, expected):
    assert normalize_rating(raw) == expected


def test_relevance_similar_claims_pass():
    assert relevance("Drinking bleach cures viral infections",
                     "Posts claim that drinking bleach cures virus infections") >= 0.5


def test_relevance_unrelated_claims_fail():
    assert relevance("Drinking bleach cures viral infections", "Penguins can fly across the Atlantic") < 0.2


def test_relevance_negation_mismatch_is_zero():
    assert relevance("Vaccines cause autism", "Vaccines do not cause autism") == 0.0
    assert relevance("Vaccines don't cause autism", "Vaccines cause autism") == 0.0


def test_relevance_both_negated_still_matches():
    assert relevance("Vaccines do not cause autism", "Claim: vaccines don't cause autism") >= 0.5


def test_relevance_empty_inputs():
    assert relevance("", "anything") == 0.0
    assert relevance("the and of", "the and of") == 0.0  # only stopwords


def test_claim_key_ignores_case_and_punctuation():
    assert claim_key("  The Earth, revolves around the SUN!! ") == claim_key("the earth revolves around the sun")


def test_canonical_url_strips_tracking_and_www():
    a = canonical_url("http://www.Example.com/a/b/?utm_source=x&id=7#frag")
    b = canonical_url("https://example.com/a/b?id=7")
    assert a == b


def test_site_root():
    assert site_root("factcheck.afp.com") == "afp.com"
    assert site_root("https://www.bbc.co.uk/news") == "bbc.co.uk"
    assert site_root("politifact.com") == "politifact.com"


def test_publisher_tier():
    assert publisher_tier("politifact.com") == SourceTier.KNOWN
    assert publisher_tier("factcheck.afp.com") == SourceTier.KNOWN   # subdomain of afp.com
    assert publisher_tier("notpolitifact.com") == SourceTier.UNKNOWN  # suffix must align on a dot
    assert publisher_tier("") == SourceTier.UNKNOWN


def _item(url, title="t", site="a.example", name="A"):
    return EvidenceItem("p", name, site, title, url, Stance.REFUTES, "False", "c", SourceTier.UNKNOWN)


def test_dedupe_by_url_and_by_publisher_title():
    items = [
        _item("https://a.example/x?utm_source=1", title="Same"),
        _item("https://www.a.example/x", title="Other"),        # same canonical URL
        _item("https://a.example/y", title="Same"),             # same publisher + title
        _item("https://b.example/y", title="Same", site="b.example", name="B"),  # different publisher: kept
    ]
    kept = dedupe(items)
    assert [i.url for i in kept] == ["https://a.example/x?utm_source=1", "https://b.example/y"]
