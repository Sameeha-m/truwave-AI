# Clear Explanations Implementation Report

## Existing architecture findings

- The active verification path opens `VerificationResultScreen` after `POST /verify` completes. It already receives a `Verification` and the returned `List<VerificationSource>`; its **View Full Explanation** button previously had no action.
- `Verification` contains non-null `claim`, `verdict`, `confidence`, `summary`, and `findings`. `VerificationSource` contains non-null `name`, `title`, and `url`. The API service validates these values before building the objects.
- The fixed-copy legacy FAKE and UNCERTAIN screens are not used by the active verification navigation. They remain in the repository and are not deleted.
- `url_launcher` is not in `flutter_app/pubspec.yaml`. Source URLs are therefore selectable text; no dependency was added.
- The architecture contract describes confidence as confidence in TruWave's classification, not the probability that a claim is true. The verifier uses fixed heuristic confidence tiers, and no public categorical confidence bands are defined. The explanation retains the existing numeric percentage and classification wording; it does not add High/Medium/Low labels.

## Implemented behavior

- Added a canonical `FullExplanationScreen` and connected the result button to it, passing the existing verification and sources directly. It makes no second API request and does not mutate the response.
- The screen presents the claim, one of REAL/FAKE/UNCERTAIN, the existing classification confidence, the backend summary, every finding, and each non-empty source name, title, and URL.
- Confidence is shown only for finite values in the existing 0–1 range. Otherwise the screen displays “Not available.” It clarifies that this is classification confidence, not probability of truth.
- The UNCERTAIN summary is retained. A brief generic evidence note is added only when the summary does not already explain uncertainty; the fallback does not assert that evidence was both insufficient and conflicting.
- An empty source list displays the exact text “No fact-checks found”. Empty summaries and findings have safe fallback copy. Partially empty source fields are omitted; a source with all fields empty displays “Source details unavailable.”
- URLs are selectable and copyable as text. They are not clickable because the existing dependencies do not include a URL-launching package.
- No raw ML scores, model identifiers, or debugging fields are read or displayed. Existing result fields and all findings are preserved.

## Files changed

- `flutter_app/lib/screens/full_explanation_screen.dart` — new explanation screen.
- `flutter_app/lib/screens/verification_result_screen.dart` — navigation from the existing button.
- `flutter_app/test/full_explanation_screen_test.dart` — widget coverage for verdicts, uncertainty, empty sources, and navigation/data reuse.
- `docs/CLEAR_EXPLANATIONS_IMPLEMENTATION_REPORT.md` — this report.

No backend, API contract, model, dependency, or legacy-screen files were changed for this task.

## Validation

- `dart format lib/screens/full_explanation_screen.dart lib/screens/verification_result_screen.dart test/full_explanation_screen_test.dart` — completed; 2 files formatted.
- `flutter test test/full_explanation_screen_test.dart` — passed, 6 tests.
- `flutter analyze` — exit code 1, with 9 existing diagnostics in other files: one warning in `lib/services/verification_service.dart` (`unnecessary_non_null_assertion`), four deprecation infos and three lint infos in the existing loading screen/tests, and one lint info in `lib/services/verification_service.dart`. The new explanation screen produced no analyzer diagnostic after using `withValues`.
- `flutter test` — exit code 1: all 6 new explanation tests passed, along with 7 other existing tests; 5 tests in `test/verification_loading_screen_test.dart` failed. The failures are in the pre-existing loading/verification flow tests, including source-title assertions and timing/navigation assertions. That loading screen and its tests were outside this task's scope and were not changed.
- `git diff --check` — passed; Git reported only line-ending normalization notices for existing modified files.

## Remaining limitation

The URL is visible and selectable, but opening it requires a separately approved dependency or platform-specific link implementation. A manual device review is still recommended for visual polish on the demo device.
