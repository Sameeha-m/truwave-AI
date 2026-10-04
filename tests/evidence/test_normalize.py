import pytest

from evidence.base import EvidenceItem, SourceTier, Stance
from evidence.normalize import (
    canonical_url, claim_key, dedupe, explain_relevance, normalize_rating, publisher_tier, relevance,
    site_root,
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


# ---- explain_relevance: the diagnostic must always agree with the real gate -------------
_PAIRS = [
    ("Drinking bleach cures COVID-19", "Drinking bleach cures COVID-19"),
    ("Drinking bleach cures COVID-19", "Drinking bleach does not cure COVID-19"),
    ("Drinking bleach cures COVID-19", "Disinfectants such as bleach can kill the virus that causes COVID-19"),
    ("Vaccines do not cause autism", "Claim: vaccines don't cause autism"),
    ("Vaccines cause autism", "Vaccines do not cause autism"),
    ("", "anything"),
    ("the and of", "the and of"),
]


@pytest.mark.parametrize("claim,reviewed", _PAIRS)
def test_explain_relevance_score_always_equals_relevance(claim, reviewed):
    assert explain_relevance(claim, reviewed).score == relevance(claim, reviewed)


def test_explain_relevance_shows_why_negation_blocked_a_full_overlap():
    b = explain_relevance("Drinking bleach cures COVID-19", "Drinking bleach does not cure COVID-19")
    assert b.blocked_by_negation is True
    assert b.score == 0.0
    assert b.overlap_score == 1.0                     # every content word is shared
    assert b.claim_negators == () and b.reviewed_negators == ("not",)
    assert b.only_in_claim == () and b.only_in_reviewed == ()


def test_explain_relevance_lists_shared_and_unshared_words():
    b = explain_relevance("Drinking bleach cures COVID-19", "Disinfectants such as bleach can kill COVID-19")
    assert b.blocked_by_negation is False
    assert b.shared == ("19", "bleach", "covid")
    assert b.only_in_claim == ("cure", "drinking")
    assert "disinfectant" in b.only_in_reviewed and "kill" in b.only_in_reviewed


def test_explain_relevance_normalises_contractions_when_listing_negators():
    assert explain_relevance("x", "Bleach doesn't cure it").reviewed_negators == ("doesnt",)


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
