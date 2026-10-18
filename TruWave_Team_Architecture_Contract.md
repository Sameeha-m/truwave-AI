# TruWave — Team Architecture & Development Contract

**Purpose:** Shared source of truth for all TruWave development chats and teammates.

## 1. Product goal
TruWave helps users verify suspicious news/claims and check whether images may be AI-generated.

Core UX: **Result → Confidence → Evidence → Explanation**

Users should not need to understand the classifier, APIs, model scores, or database architecture.

## 2. Core verification outcomes
News verification has three first-class outcomes:
- **REAL** — likely real
- **FAKE** — likely fake
- **UNCERTAIN** — insufficient or conflicting evidence

UNCERTAIN is not an error state. Do not force REAL/FAKE when evidence is weak or conflicting.

Confidence means **TruWave's confidence in its classification**, not the percentage probability that a claim is true.

## 3. Intended architecture

```text
Flutter App ──> FastAPI: POST /verify ──> Verification engine
                                            ├── TF-IDF + Logistic Regression
                                            └── Evidence / fact-check providers
                                                     │
                                        evidence-led final decision
                                                     │
                                              Result JSON ──> Flutter

Flutter App ──> Local SQLite (verification history)

Optional:
SQLite <-> Sync Layer <-> Supabase
```

### Flutter
UI, navigation, forms, loading/results, history/profile/settings, API calls and local persistence integration.

### SQLite
Local verification history. Local storage is the default.

### FastAPI
HTTP/API boundary and orchestration of verification services.

### TF-IDF + Logistic Regression
The official MVP baseline classifier is the existing scikit-learn pipeline identified as `fever-tfidf-logreg/v1`. It uses a `TfidfVectorizer` and `LogisticRegression`, trained on FEVER claim text with the labels mapped to `REAL`, `FAKE`, and `UNCERTAIN`.

TF-IDF was chosen for the MVP because it supports lightweight local inference, keeps deployment simple with the existing scikit-learn dependency, and is already integrated behind the backend's `MLClassifier` interface. The mock classifier remains available for development and tests; `ML_PROVIDER=tfidf` selects the trained model.

This is a baseline text classifier. Its learned prediction is not proof that a claim is factually true or false: it does not retrieve facts or inspect supporting evidence. The evidence providers supply fact-check context, and the verification engine combines that evidence with the internal ML signal. Insufficient or conflicting evidence can produce `UNCERTAIN`; the classifier must not force a decisive public verdict when the evidence does not support one.

Future classifier upgrades can be evaluated separately behind `MLClassifier`. They must preserve the existing API contract unless an API change is explicitly approved and documented.

### Evidence / fact-check layer
Retrieves reviewed claims and supporting or conflicting evidence and sources. Evidence is the basis for the public explanation and a primary input to the final verdict. If evidence is insufficient or conflicting, the verifier can return `UNCERTAIN`. If all configured evidence providers are unavailable, the existing service-unavailable error behavior remains in effect.

### Supabase
Optional cloud layer for account/sync functionality. Cloud sync is OFF by default.

## 4. Shared API contract

Initial endpoint:

`POST /verify`

Request:
```json
{"claim": "string"}
```

Response:
```json
{
  "verdict": "REAL | FAKE | UNCERTAIN",
  "confidence": 0.0,
  "summary": "string",
  "findings": ["string"],
  "sources": [
    {"name": "string", "title": "string", "url": "string"}
  ]
}
```

If this contract changes, document the change before changing both sides.

## 5. MVP strategy

```text
Flutter → FastAPI /verify → TF-IDF + Logistic Regression and evidence
        → evidence-led verification decision → existing result response
```

TF-IDF + Logistic Regression is the approved MVP classifier. The mock provider remains available for deterministic development and tests; it is not a silent fallback when TF-IDF is selected and unavailable.

## 6. Team ownership

**Main / Integration**
- Flutter app
- navigation
- API integration
- final integration/testing

**Backend**
- FastAPI
- `/verify`
- request/response validation
- orchestration
- API documentation

**ML**
- FEVER data and label mapping
- TF-IDF + Logistic Regression training and evaluation
- inference through the shared `MLClassifier` interface
- future model comparisons behind that interface, without an API change unless separately approved

**Database**
- SQLite schema
- persistence/retrieval/deletion
- History data access layer

**Evidence**
- evidence/source retrieval
- source normalization
- supporting/conflicting evidence structure

**Testing / QA**
- test cases
- integration checks
- edge/error cases
- regression testing

## 7. Suggested repository structure

```text
truwave/
├── flutter_app/
├── backend/
├── ml/
├── database/
├── evidence/
└── docs/
```

Avoid multiple teammates casually modifying the same files. Use Git branches and merges/pull requests.

## 8. Core user flows

```text
Onboarding
 ↓
Home
 ↓
Verify News
 ↓
Input claim
 ↓
Loading
 ↓
REAL / FAKE / UNCERTAIN
 ↓
Full Explanation / Evidence
 ↓
Save to local History
```

Image:

```text
Home → Verify Image → Upload → Loading
     → AI-generated / Likely Real
     → Explanation → Save to History
```

History:

```text
Home → History → Previous Result → Full Explanation
```

## 9. UI/source-of-truth rules

The existing Figma prototype is the visual source of truth.

Core navigation includes Home, History, central Verify action, Insights and Me/Profile, plus news verification, image verification, REAL/FAKE/UNCERTAIN results, explanation, privacy/settings, login/profile/edit-profile where implemented.

Do not redesign screens from scratch unless the project owner agrees.

## 10. Privacy rules

- Verification history is stored locally by default.
- Cloud sync is optional and OFF by default.
- Do not claim end-to-end encryption until it is actually implemented and verified.
- Do not expose raw API errors to users.
- Local history remains accessible when offline.
- New verification requires network access unless an offline model is deliberately implemented.

## 11. Error states

Support:
- Offline
- Verification failed
- Server unavailable
- Unsupported image
- Empty history

Use friendly messages and retry actions. Never expose raw stack traces/API errors in the UI.

## 12. Rules for teammate chats

Every teammate should:
1. State their workstream.
2. Follow the existing architecture before adding dependencies.
3. Work in **2–5 steps at a time**.
4. Report completed work and remaining work.
5. Preserve shared API/data contracts.
6. Avoid silently changing another team's architecture.
7. Give exact file paths and commands.
8. Test each milestone before moving on.

## 13. Current priority

The immediate MVP target is:

**Flutter → FastAPI → TF-IDF + evidence → evidence-led verification result → Flutter result → SQLite history**

Use the fixture evidence provider for deterministic development and tests. The mock ML provider remains an explicit development/test option.

## 14. Product principles

- Fast and understandable verification.
- Evidence and explanation matter, not just a model score.
- UNCERTAIN is a valid outcome.
- Never imply certainty the system cannot support.
- Keep technical ML details behind the user-facing explanation.
- Make privacy visible and understandable.

## 15. Source basis

This contract consolidates the existing TruWave project materials: UI/UX specification, information architecture and app structure. Those materials define the core navigation, REAL/FAKE/UNCERTAIN result model, evidence/explanation UX, local-history/privacy approach, optional cloud sync, and the intended Flutter → Local SQLite → Sync Layer → Optional Supabase plus Flutter → FastAPI → ML/Fact Check architecture.

If source material and a teammate's assumption conflict, stop and check the project owner rather than silently changing the architecture.
