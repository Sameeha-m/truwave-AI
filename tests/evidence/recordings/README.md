# Recorded API responses

These JSON files are used by the automated tests instead of calling Google.

- `claims_search_*.json` and `error_*.json` here were **hand-built from Google's documented
  schema** (https://developers.google.com/fact-check/tools/api/reference/rest/v1alpha1/claims).
  They are NOT captured from the live API. Publishers/URLs in them are invented (`.example`).
- Real captures: run `python scripts/check_factcheck_live.py "some claim" --save` with your key.
  It writes `live_<claim>.json` into this folder. `tests/evidence/test_recordings.py` automatically
  parses every `live_*.json` it finds, so real responses become regression tests.
  Live captures contain only Google's response body, never your key.
