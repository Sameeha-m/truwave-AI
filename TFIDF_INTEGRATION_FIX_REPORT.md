# TruWave TF-IDF Integration Fix Report

## 1. Executive summary

TF-IDF initialization failed because inference expected the original FEVER dataset labels, while the repository's training script deliberately converts those labels to TruWave's internal `REAL`, `FAKE`, and `UNCERTAIN` labels before training. The artifact contained all three intended TruWave classes. Runtime validation and prediction mapping have now been aligned with the training pipeline. The artifact was not changed or retrained.

## 2. Root cause

Verified from the current training code and artifact:

- `ml/train_truwave.py::_read_split` maps FEVER `SUPPORTS`, `REFUTES`, and `NOT ENOUGH INFO` through `FEVER_TO_ML`, then appends each mapped `MLLabel.value` as the training target.
- The saved artifact's `LogisticRegression.classes_` is `['FAKE', 'REAL', 'UNCERTAIN']`. It has three classes; none are missing.
- Artifact metadata identifies model `fever-tfidf-logreg/v1` and scikit-learn `1.9.1`. The project `.venv` also reports scikit-learn `1.9.1`.
- The old runtime check compared the saved classes with the *keys* of `FEVER_TO_ML` (`SUPPORTS`, `REFUTES`, `NOT ENOUGH INFO`). That comparison necessarily failed. Even if initialization had passed, prediction mapping attempted to look up saved class names such as `REAL` in a map keyed by the original FEVER labels.

This is a training/runtime label-representation mismatch in the code, not an omitted-class training defect, a mislabeled artifact, or a scikit-learn version mismatch.

## 3. Files changed

- `ml/tfidf.py` — define the reverse mapping for the labels actually stored by training; validate that all three TruWave labels exist; map predicted labels and class scores through that reverse mapping.
- `tests/backend/test_main.py` — assert class coverage and valid finite scores; test rejection of an artifact missing a class; exercise the real configured artifact through `/verify`; and retain a recording test double that verifies the configured provider invokes inference.
- `TFIDF_INTEGRATION_FIX_REPORT.md` — this report.

No new package was added. The training script, serialized model, evidence provider, verifier decision rules, and API response models were not changed for this fix.

## 4. Artifact status

- Path: `ml/artifacts/fever_tfidf_logreg.joblib`
- Size observed: 3,087,426 bytes.
- Classes before fix: `FAKE`, `REAL`, `UNCERTAIN` (stored as NumPy string values).
- Classes after fix: unchanged; runtime now validates and interprets those labels correctly.
- Rebuilt: no. The current training pipeline already generated the correct output-label representation.
- Backup: none needed; the artifact was read only.

## 5. Tests executed

All commands used the project environment at `.venv`.

```powershell
.\.venv\Scripts\python.exe -m pytest tests\backend\test_main.py -q
```

Result: **14 passed**, one `StarletteDeprecationWarning` about Starlette's current `TestClient` integration with `httpx`.

```powershell
.\.venv\Scripts\python.exe -m pytest -q
```

Result: **202 passed**, with the same warning.

The focused TF-IDF endpoint selection also ran successfully: **2 passed, 11 deselected**. The project `.venv` directly loaded the serialized artifact and successfully called `predict_proba`/`predict` on a claim. The first sandboxed attempts stalled while Windows asyncio was creating its local test socket; rerunning pytest outside the sandbox completed successfully. No tests remain unrun from the full repository suite.

## 6. End-to-end integration

The tests exercise `ML_PROVIDER=tfidf` with `EVIDENCE_PROVIDER=fixture`, so no live Google API request or secret is needed:

- A real `TfidfClassifier` is loaded into the FastAPI verifier and exercised through the actual in-process `/verify` ASGI route.
- A recording classifier test double confirms that the `tfidf` configuration selects the TF-IDF provider and invokes `classify` with the submitted claim. This proves provider selection and invocation without relying on a particular model prediction.
- Direct artifact inference confirms a supported `MLLabel`, finite confidence in `[0, 1]`, and a score entry for each of the three labels.
- A missing-class artifact is rejected explicitly. A missing model path is also covered and produces a configuration error; there is no silent mock fallback.
- Fixture-backed insufficient evidence still yields `UNCERTAIN` through the existing verifier rules.

## 7. API compatibility

The existing `POST /verify` endpoint remains in place. It accepts `{"claim": "string"}` and returns the existing `verdict`, `confidence`, `summary`, `findings`, and `sources` fields. Tests check the response field set, supported verdicts, finite in-range numeric confidence, and unchanged findings/source structures. No new endpoint or response field was introduced. Evidence remains part of verification, and the verifier can still return `UNCERTAIN` when evidence is insufficient or conflicting.

## 8. Limitations

This fix establishes correct loading, label mapping, inference, and backend integration. It does not establish that a text-only TF-IDF prediction is factually correct. TF-IDF learns correlations from FEVER claim text; it does not retrieve or inspect evidence. TruWave's existing verifier and evidence service remain responsible for the final verdict, and the model's internal score is not a calibrated probability of truth. The test suite verifies integration and contracts, not broad model quality or real-world generalization.

The architecture documentation has since been aligned with the approved decision to keep TF-IDF + Logistic Regression as the official MVP classifier. This follow-up changes documentation only; the implementation continues to use the existing `MLClassifier` seam. A future model upgrade can be evaluated separately without changing the public API contract.

## 9. How to run locally

From the repository root in PowerShell, use the project virtual environment:

```powershell
.\.venv\Scripts\Activate.ps1
$env:ML_PROVIDER = "tfidf"
$env:EVIDENCE_PROVIDER = "fixture"
python -m uvicorn backend.main:app --reload
```

The fixture provider is intended for deterministic local verification. To run the focused backend module or the complete test suite:

```powershell
.\.venv\Scripts\python.exe -m pytest tests\backend\test_main.py -q
.\.venv\Scripts\python.exe -m pytest -q
```

## 10. Git/change summary

This fix is limited to runtime label validation/mapping, its regression tests, and this report. The model artifact was not overwritten, and no dependencies were installed. Other pre-existing worktree changes in backend, evidence, Flutter, ML training/configuration, and related tests were preserved. No commit or push was made.
