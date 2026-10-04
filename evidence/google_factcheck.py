"""Real Google Fact Check Tools API provider (claims:search).

API reference: https://developers.google.com/fact-check/tools/api/reference/rest/v1alpha1/claims/search
Response shape (documented):
    {"claims": [{"text", "claimant", "claimDate",
                 "claimReview": [{"publisher": {"name", "site"}, "url", "title",
                                  "reviewDate", "textualRating", "languageCode"}]}],
     "nextPageToken": "..."}
An empty result is `{}` (no "claims" key).

SECURITY: the API key travels as a `key=` query parameter, so it is part of every
request URL. This module therefore never logs URLs/params, never puts a URL or
upstream body into an exception message, and never calls raise_for_status().
"""
from __future__ import annotations

import asyncio
import logging
from datetime import date, datetime
from typing import Any

import httpx

from .base import (
    EvidenceItem,
    ProviderAuthError,
    ProviderBadResponse,
    ProviderError,
    ProviderNotConfigured,
    ProviderRateLimited,
    ProviderTimeout,
    Stance,
)
from .normalize import normalize_rating, publisher_tier, site_host

# httpx logs full request URLs (including ?key=...) at INFO. Keep it quiet.
logging.getLogger("httpx").setLevel(logging.WARNING)
logging.getLogger("httpcore").setLevel(logging.WARNING)

logger = logging.getLogger("truwave.evidence.google")

ENDPOINT = "https://factchecktools.googleapis.com/v1alpha1/claims:search"
MAX_QUERY_CHARS = 300


class GoogleFactCheckProvider:
    name = "google_factcheck"

    def __init__(
        self,
        api_key: str,
        *,
        language: str = "en",
        page_size: int = 10,
        timeout_s: float = 5.0,
        max_attempts: int = 2,
        backoff_s: float = 0.3,
        client: httpx.AsyncClient | None = None,
        endpoint: str = ENDPOINT,
    ) -> None:
        self._api_key = api_key
        self._language = language
        self._page_size = page_size
        self._timeout_s = timeout_s
        self._max_attempts = max(1, max_attempts)
        self._backoff_s = backoff_s
        self._client = client
        self._endpoint = endpoint

    def __repr__(self) -> str:  # never include the key
        return f"GoogleFactCheckProvider(configured={bool(self._api_key)})"

    # ------------------------------------------------------------------ public
    async def search(self, claim: str) -> list[EvidenceItem]:
        payload = await self.fetch(claim)
        return parse_claims_payload(payload, provider=self.name)

    async def fetch(self, claim: str) -> dict[str, Any]:
        """Call the API (with retries) and return the decoded JSON object."""
        if not self._api_key:
            raise ProviderNotConfigured("FACTCHECK_API_KEY is not set")

        params: dict[str, Any] = {
            "query": claim.strip()[:MAX_QUERY_CHARS],
            "pageSize": self._page_size,
            "key": self._api_key,
        }
        if self._language:
            params["languageCode"] = self._language

        last_error: ProviderError | None = None
        for attempt in range(1, self._max_attempts + 1):
            try:
                return await self._attempt(params)
            except (ProviderTimeout, _Retryable) as exc:
                last_error = exc if isinstance(exc, ProviderError) else exc.error
                logger.warning(
                    "fact check attempt %d/%d failed: %s", attempt, self._max_attempts, last_error.code
                )
                if attempt < self._max_attempts:
                    await asyncio.sleep(self._backoff_s * attempt)
        assert last_error is not None
        raise last_error

    # ----------------------------------------------------------------- private
    async def _attempt(self, params: dict[str, Any]) -> dict[str, Any]:
        try:
            if self._client is not None:
                response = await self._client.get(self._endpoint, params=params, timeout=self._timeout_s)
            else:
                async with httpx.AsyncClient() as client:
                    response = await client.get(self._endpoint, params=params, timeout=self._timeout_s)
        except httpx.TimeoutException:
            raise ProviderTimeout("fact check request timed out") from None
        except httpx.HTTPError:
            # Do not chain/format the exception: its text can contain the request URL.
            raise _Retryable(ProviderError("fact check service unreachable", code="unavailable")) from None

        status = response.status_code
        if status == 200:
            return _decode_json_object(response)
        reason = _error_reason(response)
        if status == 429 or reason == "RESOURCE_EXHAUSTED":
            raise ProviderRateLimited("fact check rate limit reached", reason=reason)
        # Google reports a bad key as HTTP 400 + reason API_KEY_INVALID, so look at the
        # reason as well as the status code.
        if status in (401, 403) or _is_auth_reason(reason):
            raise ProviderAuthError("fact check API key rejected or API not enabled", reason=reason)
        if status == 400:
            raise ProviderError("fact check request was rejected", code="bad_request", reason=reason)
        if status >= 500:
            raise _Retryable(ProviderError("fact check service error", code="unavailable", reason=reason))
        raise ProviderError("unexpected fact check response", code="unavailable", reason=reason)


class _Retryable(Exception):
    def __init__(self, error: ProviderError) -> None:
        super().__init__(error.code)
        self.error = error


# ---------------------------------------------------------------------- parsing
def _decode_json_object(response: httpx.Response) -> dict[str, Any]:
    try:
        payload = response.json()
    except ValueError:
        raise ProviderBadResponse("fact check response was not valid JSON") from None
    if not isinstance(payload, dict):
        raise ProviderBadResponse("fact check response had an unexpected shape")
    return payload


_AUTH_REASONS = frozenset({"SERVICE_DISABLED", "PERMISSION_DENIED", "UNAUTHENTICATED", "ACCESS_DENIED"})


def _is_auth_reason(reason: str | None) -> bool:
    return bool(reason) and (reason.startswith("API_KEY") or reason in _AUTH_REASONS)


def _error_reason(response: httpx.Response) -> str | None:
    """Pull Google's enumerated error reason (e.g. API_KEY_INVALID) or status, if present."""
    try:
        body = response.json()
        error = body.get("error", {}) if isinstance(body, dict) else {}
        for detail in error.get("details", []) or []:
            if isinstance(detail, dict) and isinstance(detail.get("reason"), str):
                return detail["reason"][:64]
        status = error.get("status")
        return status[:64] if isinstance(status, str) else None
    except (ValueError, AttributeError, TypeError):
        return None


def _str(value: Any) -> str:
    return value.strip() if isinstance(value, str) else ""


def _parse_date(value: Any) -> date | None:
    text = _str(value)
    if not text:
        return None
    try:
        return datetime.fromisoformat(text.replace("Z", "+00:00")).date()
    except ValueError:
        return None


def parse_claims_payload(payload: dict[str, Any], *, provider: str = "google_factcheck") -> list[EvidenceItem]:
    """Turn a claims:search payload into EvidenceItems.

    - `{}` / missing "claims"        -> [] (nothing found; not an error)
    - claims is not a list           -> ProviderBadResponse
    - individual malformed entries   -> skipped
    - every entry malformed          -> ProviderBadResponse (looks like schema drift, not "no evidence")
    """
    if not isinstance(payload, dict):
        raise ProviderBadResponse("fact check response had an unexpected shape")
    claims = payload.get("claims")
    if claims is None:
        return []
    if not isinstance(claims, list):
        raise ProviderBadResponse("fact check 'claims' was not a list")

    items: list[EvidenceItem] = []
    structurally_invalid = 0
    for claim in claims:
        reviews = claim.get("claimReview") if isinstance(claim, dict) else None
        if not isinstance(reviews, list):
            structurally_invalid += 1
            continue
        reviewed_text = _str(claim.get("text"))
        for review in reviews:
            item = _parse_review(review, reviewed_text, provider)
            if item is not None:
                items.append(item)

    if claims and structurally_invalid == len(claims):
        raise ProviderBadResponse("fact check response did not contain readable reviews")
    return items


def _parse_review(review: Any, reviewed_text: str, provider: str) -> EvidenceItem | None:
    if not isinstance(review, dict):
        return None
    url = _str(review.get("url"))
    if not url.lower().startswith(("http://", "https://")):
        return None  # Flutter shows a link; an item without one is unusable.

    publisher = review.get("publisher") if isinstance(review.get("publisher"), dict) else {}
    site = site_host(_str(publisher.get("site")) or url)
    name = _str(publisher.get("name")) or site or "Unknown publisher"
    rating = _str(review.get("textualRating"))
    title = _str(review.get("title")) or reviewed_text or name

    return EvidenceItem(
        provider=provider,
        publisher_name=name,
        publisher_site=site,
        title=title,
        url=url,
        stance=normalize_rating(rating),
        raw_rating=rating,
        reviewed_claim=reviewed_text or title,
        tier=publisher_tier(site or url),
        review_date=_parse_date(review.get("reviewDate")),
    )
