"""The live-check script's per-review report (scripts/check_factcheck_live.py).

It must list every parsed review, including ones the relevance gate rejects, and never fail
on odd characters. Uses a saved recording; no network.
"""
import importlib.util
import json

from evidence.google_factcheck import parse_claims_payload
from tests.helpers import RECORDINGS

SCRIPT = RECORDINGS.parents[2] / "scripts" / "check_factcheck_live.py"


def _load_script():
    spec = importlib.util.spec_from_file_location("check_factcheck_live", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _items(name="claims_search_refuted.json"):
    return parse_claims_payload(json.loads((RECORDINGS / name).read_text(encoding="utf-8")))


def test_report_has_one_block_per_review_including_rejected_ones():
    script = _load_script()
    items = _items()
    # A claim unrelated to the recording => every review is rejected, but all must still be listed.
    text = "\n".join(script.format_relevance_report("Penguins can fly across the Atlantic", items, 0.5))
    assert text.count("result         :") == len(items) > 0
    assert "PASSED" not in text and "FAILED" in text
    for item in items:
        assert item.publisher_name in text


def test_report_marks_matching_reviews_as_passed():
    script = _load_script()
    text = "\n".join(script.format_relevance_report("Drinking bleach cures viral infections", _items(), 0.5))
    assert "PASSED" in text


def test_report_explains_a_negation_block():
    script = _load_script()
    items = _items()
    # The user's claim is negated, the recordings' reviewed claims are not.
    text = "\n".join(script.format_relevance_report("Drinking bleach does not cure viral infections", items, 0.5))
    assert "negation guard" in text and "forced to 0" in text


def test_report_never_contains_a_key_value(monkeypatch):
    monkeypatch.setenv("FACTCHECK_API_KEY", "AIzaSyFAKE-KEY-FOR-TEST-0123456789")
    script = _load_script()
    text = "\n".join(script.format_relevance_report("Drinking bleach cures viral infections", _items(), 0.5))
    assert "AIzaSy" not in text
