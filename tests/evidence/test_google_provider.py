import json
import logging

import httpx
import pytest

from evidence.base import (
    ProviderAuthError, ProviderBadResponse, ProviderError, ProviderNotConfigured,
    ProviderRateLimited, ProviderTimeout, SourceTier, Stance,
)
from evidence.google_factcheck import GoogleFactCheckProvider, parse_claims_payload
from tests.helpers import recording, run

SECRET = "AIzaSyTESTKEY-do-not-leak-0123456789"


def provider_with(handler, **kw):
    client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    kw.setdefault("backoff_s", 0)
    return GoogleFactCheckProvider(SECRET, client=client, **kw)


def respond(payload, status=200):
    return lambda request: httpx.Response(status, json=payload)


# ------------------------------------------------------------- happy path
def test_parses_recorded_refuted_response():
    items = run(provider_with(respond(recording("claims_search_refuted.json"))).search("bleach"))
    assert len(items) == 4  # 1 + 2 + 1 reviews (duplicates are removed later, by the service)
    first = items[0]
    assert first.publisher_name == "Example Fact Check One"
    assert first.publisher_site == "example-factcheck-one.example"
    assert first.stance == Stance.REFUTES
    assert first.raw_rating == "False"
    assert first.reviewed_claim.startswith("Posts claim that drinking bleach")
    assert str(first.review_date) == "2024-03-05"
    assert first.tier == SourceTier.UNKNOWN
    assert any(i.raw_rating == "Pants on Fire" and i.stance == Stance.REFUTES for i in items)
    assert any(i.raw_rating == "Falsch" and i.stance == Stance.UNRATED for i in items)  # non-English


def test_request_shape():
    seen = {}

    def handler(request: httpx.Request):
        seen["params"] = dict(request.url.params)
        seen["host"] = request.url.host
        return httpx.Response(200, json={})

    run(provider_with(handler, language="en", page_size=7).search("x" * 500))
    assert seen["host"] == "factchecktools.googleapis.com"
    assert seen["params"]["key"] == SECRET
    assert seen["params"]["languageCode"] == "en"
    assert seen["params"]["pageSize"] == "7"
    assert len(seen["params"]["query"]) == 300


def test_language_omitted_when_blank():
    seen = {}

    def handler(request):
        seen["params"] = dict(request.url.params)
        return httpx.Response(200, json={})

    run(provider_with(handler, language="").search("x"))
    assert "languageCode" not in seen["params"]


def test_empty_object_means_no_results_not_an_error():
    assert run(provider_with(respond(recording("claims_search_empty.json"))).search("x")) == []


# ------------------------------------------------------------- robustness
def test_partial_garbage_skips_bad_entries_but_keeps_good_ones():
    items = parse_claims_payload(recording("claims_search_partial_garbage.json"))
    # Skipped: non-object claim, claim without "claimReview", non-object review, review without a URL.
    # Kept: a review with a valid URL but a malformed publisher (name falls back to its site) + the good one.
    assert [i.publisher_name for i in items] == ["junk.example", "Good Publisher"]
    good = next(i for i in items if i.publisher_name == "Good Publisher")
    assert good.stance == Stance.SUPPORTS and good.review_date is None  # bad date tolerated


def test_all_entries_malformed_is_bad_response_not_empty():
    with pytest.raises(ProviderBadResponse):
        parse_claims_payload(recording("claims_search_all_malformed.json"))


@pytest.mark.parametrize("payload", [["list"], "text", 5, {"claims": "oops"}, {"claims": {"a": 1}}])
def test_wrong_top_level_shapes_are_bad_response(payload):
    with pytest.raises(ProviderBadResponse):
        parse_claims_payload(payload)


def test_non_json_body_is_bad_response():
    handler = lambda request: httpx.Response(200, content=b"<html>not json</html>")
    with pytest.raises(ProviderBadResponse):
        run(provider_with(handler).search("x"))


def test_json_array_body_is_bad_response():
    with pytest.raises(ProviderBadResponse):
        run(provider_with(respond(["not", "an", "object"])).search("x"))


# ------------------------------------------------------------- error handling
def test_missing_key_raises_before_any_request():
    called = []
    client = httpx.AsyncClient(transport=httpx.MockTransport(lambda r: called.append(r) or httpx.Response(200, json={})))
    with pytest.raises(ProviderNotConfigured):
        run(GoogleFactCheckProvider("", client=client).search("x"))
    assert called == []


def test_invalid_key_400_is_an_auth_error_with_reason():
    with pytest.raises(ProviderAuthError) as info:
        run(provider_with(respond(recording("error_400_api_key_invalid.json"), 400)).search("x"))
    assert info.value.reason == "API_KEY_INVALID"


def test_service_disabled_403_is_an_auth_error():
    with pytest.raises(ProviderAuthError) as info:
        run(provider_with(respond(recording("error_403_service_disabled.json"), 403)).search("x"))
    assert info.value.reason == "SERVICE_DISABLED"


def test_429_is_rate_limited_and_not_retried():
    calls = []

    def handler(request):
        calls.append(1)
        return httpx.Response(429, json=recording("error_429_quota.json"))

    with pytest.raises(ProviderRateLimited):
        run(provider_with(handler, max_attempts=3).search("x"))
    assert len(calls) == 1


def test_plain_400_is_bad_request_not_retried():
    calls = []

    def handler(request):
        calls.append(1)
        return httpx.Response(400, json={"error": {"status": "INVALID_ARGUMENT"}})

    with pytest.raises(ProviderError) as info:
        run(provider_with(handler, max_attempts=3).search("x"))
    assert info.value.code == "bad_request" and len(calls) == 1


def test_5xx_is_retried_then_succeeds():
    calls = []

    def handler(request):
        calls.append(1)
        if len(calls) == 1:
            return httpx.Response(503, text="busy")
        return httpx.Response(200, json=recording("claims_search_mixed.json"))

    items = run(provider_with(handler, max_attempts=2).search("coffee"))
    assert len(calls) == 2 and len(items) == 2


def test_5xx_every_time_gives_unavailable():
    with pytest.raises(ProviderError) as info:
        run(provider_with(lambda r: httpx.Response(500, text="x"), max_attempts=2).search("x"))
    assert info.value.code == "unavailable"


def test_timeout_is_retried_then_reported():
    calls = []

    def handler(request):
        calls.append(1)
        raise httpx.ReadTimeout("slow", request=request)

    with pytest.raises(ProviderTimeout):
        run(provider_with(handler, max_attempts=2).search("x"))
    assert len(calls) == 2


def test_network_error_is_unavailable():
    def handler(request):
        raise httpx.ConnectError("no route", request=request)

    with pytest.raises(ProviderError) as info:
        run(provider_with(handler, max_attempts=1).search("x"))
    assert info.value.code == "unavailable"


# ------------------------------------------------------------- secrets
def test_key_never_appears_in_errors_logs_or_repr(caplog):
    caplog.set_level(logging.DEBUG)

    def handler(request):
        raise httpx.ConnectError(f"cannot connect to {request.url}", request=request)  # URL contains the key

    provider = provider_with(handler, max_attempts=2)
    with pytest.raises(ProviderError) as info:
        run(provider.search("x"))

    haystack = " | ".join([str(info.value), repr(info.value), repr(provider), caplog.text])
    assert SECRET not in haystack
    assert "AIza" not in haystack
    assert info.value.__cause__ is None  # the URL-bearing exception is not chained
