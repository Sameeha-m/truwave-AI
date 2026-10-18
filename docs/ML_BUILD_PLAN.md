# TruWave ML Build Plan

**Status:** TF-IDF baseline integrated; four-step loading animation is implemented in Flutter and is presentation-only  
**Selected approach:** TF-IDF + Logistic Regression trained on FEVER  
**Product boundary:** Google Fact Check remains the only live evidence provider. The ML prediction and its score remain internal and are not shown in the UI. User-facing explanations come from evidence only.

## Implementation snapshot

The first baseline has been trained and wired to the backend. On the official labelled FEVER development split (19,998 claims), this TF-IDF + Logistic Regression run achieved **55% accuracy and 0.55 macro F1**. Per-class F1 was 0.55 for `REAL`, 0.63 for `FAKE`, and 0.49 for `UNCERTAIN`. At the verifier's current 0.80 strong-signal threshold, 18.4% of development claims had a maximum class score at or above the threshold. These are baseline results, not a guarantee of performance on user claims outside FEVER.

## 1. Goal

Replace the mock ML classifier with a small, locally runnable, three-class claim-text classifier. It will provide an internal signal to the existing verification engine. It will not retrieve facts, produce user-facing explanations, or independently establish that a claim is true or false.

## 2. Decisions to preserve

### Decision record — official MVP classifier (approved 2026-10-18)

- The official TruWave MVP classifier is the existing scikit-learn TF-IDF + Logistic Regression pipeline, model ID `fever-tfidf-logreg/v1`, trained on FEVER claims.
- TF-IDF was selected for lightweight local inference, simpler deployment, and because the implementation is already integrated behind the shared `MLClassifier` interface.
- This is a baseline claim-text classifier, not proof of factual truth. It does not retrieve facts; evidence remains central to the public verification decision and explanations.
- Keep `REAL`, `FAKE`, and `UNCERTAIN`, and preserve the current `POST /verify` contract. Evaluate any future classifier upgrade separately behind `MLClassifier`; do not change the API contract unless separately approved.

- Use FEVER as the supervised dataset.
- Keep Google Fact Check as the sole evidence provider for live verification.
- Keep the final public verdict and explanation in the existing verification/evidence pipeline.
- Do not expose the ML predicted label or its class score in the API response, persisted history, or UI. The verifier may use the internal prediction under its existing rules.
- The four generic loading steps are a Flutter-only animation while the existing `POST /verify` request runs. The response controls completion; do not add a backend progress signal or imply that the animation reports live backend stages.

## 3. Dataset and label mapping

Use the official [FEVER dataset](https://fever.ai/dataset/fever.html), distributed as JSONL records with `id`, `claim`, `label`, and `evidence` fields. Train on the official training split and evaluate on the labelled development split. Do not use the blind test set for reported metrics because its labels are withheld.

| FEVER label | Internal ML label | Meaning in this project |
|---|---|---|
| `SUPPORTS` | `REAL` | FEVER evidence supports the claim |
| `REFUTES` | `FAKE` | FEVER evidence refutes the claim |
| `NOT ENOUGH INFO` | `UNCERTAIN` | FEVER’s reference material did not settle the claim |

`NOT ENOUGH INFO` is not a universal assertion that a claim cannot be decided. FEVER claims are Wikipedia-derived and were assessed against a fixed Wikipedia snapshot. The trained model should be described as a **FEVER-trained claim classifier**, not a fact database or a general truth detector.

For the first version, train from `claim` text only. Do not use FEVER’s annotated gold evidence as model input at inference unless the application also retrieves equivalent evidence at runtime; doing so would create a training/inference mismatch. Google Fact Check remains a separate evidence path and does not currently query FEVER or its Wikipedia snapshot.

## 4. What already exists

- `ml/base.py` defines `MLClassifier`, `MLResult`, and `MLLabel` (`REAL`, `FAKE`, `UNCERTAIN`). It is a suitable replaceable interface.
- `ml/mock.py` implements a deterministic mock, currently returning `UNCERTAIN` by default.
- `backend/verifier.py` runs ML and evidence concurrently. Evidence is primary; ML may corroborate, be neutral, or oppose. Missing/weak/conflicting evidence can produce `UNCERTAIN`.
- `backend/main.py` exposes `POST /verify` and builds the configured pipeline.
- `backend/config.py` accepts the explicit `mock` and `tfidf` providers; TF-IDF is selected with `ML_PROVIDER=tfidf` and does not silently fall back to mock if its artifact is unavailable.
- `ml/train_truwave.py` trains the FEVER TF-IDF + Logistic Regression pipeline; `ml/tfidf.py` loads model `fever-tfidf-logreg/v1` and maps FEVER source labels to TruWave's three internal labels.
- `evidence/google_factcheck.py` and `evidence/service.py` implement live fact-check lookup and evidence normalization. The current verifier returns HTTP 503 if all evidence providers are unavailable; that behavior remains unchanged.
- Flutter has result screens and four animated loading steps. They are UI-only and do not represent backend progress.

## 5. Implementation sequence

### Phase 1 — Data preparation

1. Download FEVER’s training and labelled development JSONL files from the official dataset page.
2. Read JSONL with Python’s standard library; use only `claim` and `label` for the initial model.
3. Validate required fields and allowed labels, inspect class counts and empty/duplicate claims, and preserve the official split.
4. Keep the dataset out of the app bundle; document its source, citation, and license requirements.

### Phase 2 — Train and evaluate the baseline

1. Build a scikit-learn `Pipeline` containing a `TfidfVectorizer` and `LogisticRegression`.
2. Start with simple word n-grams and a reproducible random seed. Keep preprocessing minimal so claims remain interpretable and the baseline is easy to explain in a viva.
3. Evaluate on the labelled FEVER development split. Report accuracy, macro F1, per-class precision/recall/F1, and a confusion matrix. Macro F1 is important because FEVER’s training labels are imbalanced.
4. Select any abstention threshold using a validation slice of training data, not by tuning against the final reported development results. Treat `predict_proba` as a model score, not as a calibrated probability unless calibration is separately evaluated.
5. Save the complete vectorizer-plus-classifier pipeline with a stable model ID and record its training-data version and evaluation metrics.

### Phase 3 — Implement the backend classifier

1. Add a concrete scikit-learn classifier implementing `MLClassifier.classify(claim)`.
2. Load the serialized pipeline once at backend startup, not once per request.
3. Convert class predictions and scores into an internal `MLResult`, including model ID and latency. Map the FEVER source labels into `MLLabel.REAL`, `MLLabel.FAKE`, and `MLLabel.UNCERTAIN`. The verifier treats a low-score REAL/FAKE prediction as neutral under its existing threshold and keeps evidence central to the public verdict.
4. Add an explicit `tfidf` ML provider setting and constructor in `backend/config.py` / `backend/main.py`. Preserve `mock` for development. Do not silently fall back to a mock if the selected trained-model artifact is missing or invalid; return a clear startup/configuration error.
5. Keep timeout and failure degradation behavior: an ML failure is recorded internally and does not itself break verification. Evidence behavior remains unchanged.

### Phase 4 — Preserve public behavior and explanations

1. Keep the raw ML label, class scores, and model details out of `VerifyResponse`, saved history, and Flutter UI.
2. Keep user-facing findings and explanations sourced only from fact-check evidence (or the existing no-evidence wording). Do not add ML feature/word explanations.
3. Keep public findings and explanations evidence-only; do not add classifier-derived reasoning text.
4. Preserve the existing distinction between public verdict confidence and raw ML class score. If the UI displays the verifier’s rule-based confidence, label it as TruWave’s overall confidence; never substitute or expose the classifier’s `predict_proba` score.

### Phase 5 — Integration and demo readiness

1. Run the backend with the trained `tfidf` provider and the existing Google Fact Check provider; keep Google as the only live evidence source.
2. Check a curated set of representative claims end to end, including evidence-supported, evidence-refuted, no-match, and conflicting-evidence cases. Record the actual outcomes and sources for the demo; do not use fictional fixture sources as real evidence.
3. Confirm public responses contain only the agreed verdict, overall confidence, evidence-only summary/findings, and fact-check sources—not ML labels or ML scores.
4. Confirm an unavailable ML model degrades safely and an unavailable Google provider retains the current 503 behavior.
5. Keep the four-step loading animation on the Flutter side. It advances visually while the request runs, remains on its final stage if needed, and shows the result or existing error only when the actual request completes.

## 6. Architecture changes in the MVP

- The scikit-learn dependency and FEVER training/model-loading code are in place; Transformers and PyTorch are not needed for this baseline.
- The backend composition root supports `tfidf` and loads the model artifact from the configured path. A missing or invalid artifact fails explicitly; it does not silently use mock output.
- The architecture contract now records the approved TF-IDF MVP decision while retaining the generic `MLClassifier` seam.
- Public explanations remain evidence-only.
- The four-step loading animation is client-side. No backend progress endpoint or progress channel is part of the MVP.

No schema change to the public verification response is intended for the ML integration. Raw ML fields stay internal.

## 7. Logical limitations and safeguards

- **Pattern learning is not retrieval.** TF-IDF + Logistic Regression predicts based on lexical patterns associated with FEVER labels; it does not look up or prove facts.
- **Dataset mismatch remains.** FEVER uses Wikipedia-derived claims and a historical snapshot; performance on arbitrary current claims, long pasted articles, or different writing styles may be lower.
- **Evidence coverage governs the public verdict.** The existing Google Fact Check provider only finds claims that have already been reviewed and indexed. No match should remain `UNCERTAIN`; it must not be converted into `REAL` or `FAKE` just because the classifier has a preferred class.
- **`UNCERTAIN` has two internal causes.** It may be the FEVER `NOT ENOUGH INFO` class or an abstention due to a weak classifier score. Both remain hidden ML signals; the verifier’s evidence rules determine the public outcome.
- **Confidence is not calibrated by default.** Logistic Regression probabilities and the verifier’s existing fixed rule-based confidence tiers are different quantities. Keep them separate and describe only the public verifier confidence in the UI.
- **Evidence outage is not an uncertain result.** Preserve the current 503 response when all evidence providers fail; do not imply that the system checked and found uncertainty when it could not check.

## 8. Review/acceptance checklist

- [x] The FEVER train/development split and label mapping are recorded and reproducible.
- [x] The TF-IDF + Logistic Regression baseline has per-class and macro-F1 evaluation results documented.
- [x] A serialized model loads once and implements the existing `MLClassifier` interface.
- [x] The backend can explicitly select the `tfidf` provider; a missing artifact does not silently use mock output.
- [x] ML output and score remain absent from API/UI/history; user explanations contain evidence-derived text only.
- [x] The verifier preserves its evidence-led REAL/FAKE/UNCERTAIN and provider-outage behavior.
- [ ] Demo claims and their real Google Fact Check source outcomes have been rehearsed and documented.
- [x] The loading screen has four generic Flutter-side animated steps; request completion still comes from the existing `/verify` response.

## 9. Scope exclusions for this build

- No DistilBERT fine-tuning or PyTorch runtime.
- No FEVER/Wikipedia retrieval in the live evidence path.
- No second fact-check provider.
- No ML feature attribution or ML reasoning text in the explanation UI.
- No guarantee that arbitrary claims receive a decisive verdict; evidence may be absent or unavailable.
