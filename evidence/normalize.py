"""Pure helpers that turn messy provider data into comparable evidence.

Everything here is deterministic and dependency-free so it is easy to unit test.
"""
from __future__ import annotations

import json
import math
import re
from functools import lru_cache
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from .base import EvidenceItem, SourceTier, Stance

PUBLISHERS_FILE = Path(__file__).with_name("publishers.json")


# --------------------------------------------------------------------------
# Rating text -> Stance
# --------------------------------------------------------------------------
# Publishers use free-text ratings ("Pants on Fire", "Half True", "Missing context").
# Order matters: UNRATED, then MIXED, then REFUTES, then SUPPORTS. That way
# "half true" is MIXED (not SUPPORTS) and "not true" is REFUTES (not SUPPORTS).
# Anything we do not recognise (including non-English ratings) becomes UNRATED and
# is ignored by the verdict engine - the conservative choice.
_UNRATED_RE = re.compile(r"\b(satire|satirical|parody|opinion|not rated|unrated|no rating)\b")
_MIXED_RE = re.compile(
    r"\b(half|mixture|mixed|partly|partially|partial|missing context|lacks? context|"
    r"needs? context|out of context|outdated|misleading|unproven|unverified|unconfirmed|"
    r"unsupported|no evidence|unclear|disputed|exaggerated|exaggeration|cherry ?picked|"
    r"miscaptioned|misattributed)\b"
)
_REFUTES_RE = re.compile(
    r"\b(false|fake|hoax|fabricated|incorrect|inaccurate|wrong|untrue|debunked|bogus|"
    r"baseless|scam|fiction|lie|lies|pants (on )?fire|"
    r"not (entirely |completely |really )?(true|accurate|correct))\b"
)
_SUPPORTS_RE = re.compile(
    r"\b(true|correct|accurate|real|legit|legitimate|authentic|genuine|factual|confirmed)\b"
)


def normalize_rating(raw: str | None) -> Stance:
    if not raw or not isinstance(raw, str):
        return Stance.UNRATED
    text = re.sub(r"[^a-z0-9]+", " ", raw.lower()).strip()
    if not text:
        return Stance.UNRATED
    if _UNRATED_RE.search(text):
        return Stance.UNRATED
    if _MIXED_RE.search(text):
        return Stance.MIXED
    if _REFUTES_RE.search(text):
        return Stance.REFUTES
    if _SUPPORTS_RE.search(text):
        return Stance.SUPPORTS
    return Stance.UNRATED


# --------------------------------------------------------------------------
# Claim text matching (relevance)
# --------------------------------------------------------------------------
_STOPWORDS = frozenset(
    "a an the and or but if of to in on at by for with from as is are was were be been being "
    "it its this that these those there here i you he she we they them their his her our your "
    "do does did has have had will would can could should may might must about over into than "
    "then so such also very just claim claims says say said saying post posts video photo "
    "image shared viral social media facebook twitter".split()
)
_NEGATORS = frozenset(
    "not no never none cannot cant wont dont doesnt didnt isnt arent wasnt werent hasnt "
    "havent hadnt wouldnt shouldnt couldnt neither nor".split()
)
_WORD_RE = re.compile(r"[^\W_]+", re.UNICODE)


def _words(text: str) -> list[str]:
    text = text.lower().replace("'", "").replace("’", "")
    return _WORD_RE.findall(text)


def _stem(word: str) -> str:
    # Very light plural handling so "cures" matches "cure". Deliberately simple.
    if len(word) > 3 and word.endswith("s") and not word.endswith("ss"):
        return word[:-1]
    return word


def content_tokens(text: str) -> set[str]:
    return {_stem(w) for w in _words(text) if w not in _STOPWORDS and w not in _NEGATORS}


def has_negation(text: str) -> bool:
    return any(w in _NEGATORS for w in _words(text))


def relevance(claim: str, reviewed_claim: str) -> float:
    """0..1 similarity between the user's claim and the claim a fact-checker reviewed.

    Score = |overlap| / sqrt(|A| * |B|) on content words. If exactly one of the two
    texts contains a negation ("X causes Y" vs "X does not cause Y"), the score is 0:
    a rating for one must never be applied to the opposite statement. This guard is
    crude (it will also drop some valid matches); that errs on the safe side.
    """
    a, b = content_tokens(claim), content_tokens(reviewed_claim)
    if not a or not b:
        return 0.0
    if has_negation(claim) != has_negation(reviewed_claim):
        return 0.0
    return len(a & b) / math.sqrt(len(a) * len(b))


def claim_key(claim: str) -> str:
    """Canonical lookup key for a claim (used by the fixture provider)."""
    return " ".join(_words(claim))


# --------------------------------------------------------------------------
# URLs, sites, publisher tiers
# --------------------------------------------------------------------------
_TRACKING_PARAMS = ("utm_", "fbclid", "gclid", "mc_", "ref", "source")
_TWO_PART_SUFFIXES = frozenset({"co.uk", "org.uk", "co.in", "com.au", "co.za", "com.br"})


def canonical_url(url: str) -> str:
    try:
        parts = urlsplit(url.strip())
    except ValueError:
        return url.strip().lower()
    host = (parts.hostname or "").lower()
    if host.startswith("www."):
        host = host[4:]
    query = [
        (k, v)
        for k, v in parse_qsl(parts.query, keep_blank_values=True)
        if not k.lower().startswith(_TRACKING_PARAMS)
    ]
    path = parts.path.rstrip("/") or ""
    return urlunsplit(("https", host, path, urlencode(query), ""))


def site_host(site_or_url: str) -> str:
    value = (site_or_url or "").strip().lower()
    if "://" in value:
        value = urlsplit(value).hostname or ""
    value = value.split("/")[0]
    return value[4:] if value.startswith("www.") else value


def site_root(site_or_url: str) -> str:
    """Registrable-ish domain used to decide whether two sources are independent."""
    host = site_host(site_or_url)
    labels = host.split(".")
    if len(labels) <= 2:
        return host
    if ".".join(labels[-2:]) in _TWO_PART_SUFFIXES:
        return ".".join(labels[-3:])
    return ".".join(labels[-2:])


@lru_cache(maxsize=1)
def _known_sites() -> tuple[str, ...]:
    try:
        data = json.loads(PUBLISHERS_FILE.read_text(encoding="utf-8"))
        sites = data.get("known_sites", [])
        return tuple(s.strip().lower() for s in sites if isinstance(s, str) and s.strip())
    except (OSError, ValueError):
        return ()


def publisher_tier(site_or_url: str) -> SourceTier:
    host = site_host(site_or_url)
    if not host:
        return SourceTier.UNKNOWN
    for known in _known_sites():
        if host == known or host.endswith("." + known):
            return SourceTier.KNOWN
    return SourceTier.UNKNOWN


def publisher_identity(item: EvidenceItem) -> str:
    """Key for 'distinct publisher' counting."""
    return site_root(item.publisher_site or item.url) or item.publisher_name.strip().lower()


# --------------------------------------------------------------------------
# De-duplication
# --------------------------------------------------------------------------
def _title_key(title: str) -> str:
    return " ".join(_words(title))


def dedupe(items: list[EvidenceItem]) -> list[EvidenceItem]:
    """Drop repeats: same canonical URL, or same publisher + same title.

    Input order is preserved, so sort first if you want the best copy kept.
    """
    seen_urls: set[str] = set()
    seen_titles: set[tuple[str, str]] = set()
    kept: list[EvidenceItem] = []
    for item in items:
        url_key = canonical_url(item.url)
        title_key = (publisher_identity(item), _title_key(item.title))
        if url_key in seen_urls or (title_key[1] and title_key in seen_titles):
            continue
        seen_urls.add(url_key)
        seen_titles.add(title_key)
        kept.append(item)
    return kept
