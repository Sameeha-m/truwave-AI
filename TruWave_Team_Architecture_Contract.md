# TruWave — Team Architecture & Development Contract

**Purpose:** Shared source of truth for all TruWave development chats and teammates.

## 1. Product goal
TruWave helps users verify suspicious news/claims and check whether images may be AI-generated.

Core UX: **Result → Confidence → Evidence → Explanation**

Users should not need to understand DistilBERT, APIs, model probabilities, or database architecture.

## 2. Core verification outcomes
News verification has three first-class outcomes:
- **REAL** — likely real
- **FAKE** — likely fake
- **UNCERTAIN** — insufficient or conflicting evidence

UNCERTAIN is not an error state. Do not force REAL/FAKE when evidence is weak or conflicting.

Confidence means **TruWave's confidence in its classification**, not the percentage probability that a claim is true.

## 3. Intended architecture

```text
                 TRUWAVE
                    |
              Flutter App
               /                     /                 Local SQLite    FastAPI
            |              |
        History       Verification API
                           |
                 +---------+---------+
                 |                   |
             DistilBERT        Evidence / Fact-check
                 |                   |
                 +---------+---------+
                           |
                      Result JSON
                           |
                        Flutter

Optional:
SQLite <-> Sync Layer <-> Supabase
```

### Flutter
UI, navigation, forms, loading/results, history/profile/settings, API calls and local persistence integration.

### SQLite
Local verification history. Local storage is the default.

### FastAPI
HTTP/API boundary and orchestration of verification services.

### DistilBERT
ML classification/inference. It is one component of the verification pipeline, not the whole product.

### Evidence / fact-check layer
Provides supporting/conflicting evidence and sources.

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

Do not block Flutter on the final ML model.

```text
Flutter → FastAPI → Mock result → Flutter result screen
```

Then replace the mock service with:

```text
FastAPI → DistilBERT + Evidence → Final result
```

This allows parallel work.

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
- DistilBERT
- preprocessing
- inference
- model evaluation
- backend-facing model interface

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

**Flutter → FastAPI → verification result → Flutter result → SQLite history**

Mock verification responses are acceptable while ML/evidence work continues in parallel.

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
