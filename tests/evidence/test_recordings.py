"""Parses every captured live response (live_*.json), if you have saved any.

Create them with: python scripts/check_factcheck_live.py "claim" --save
"""
import json

import pytest

from evidence.google_factcheck import parse_claims_payload
from tests.helpers import RECORDINGS

LIVE = sorted(RECORDINGS.glob("live_*.json"))


@pytest.mark.skipif(not LIVE, reason="no live recordings saved yet")
@pytest.mark.parametrize("path", LIVE, ids=[p.name for p in LIVE])
def test_real_google_responses_parse(path):
    payload = json.loads(path.read_text(encoding="utf-8"))
    items = parse_claims_payload(payload)  # must not raise
    for item in items:
        assert item.url.startswith("http")
        assert item.publisher_name and item.title
