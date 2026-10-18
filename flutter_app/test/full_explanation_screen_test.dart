import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/database/source_model.dart';
import 'package:flutter_app/database/verification_model.dart';
import 'package:flutter_app/screens/full_explanation_screen.dart';
import 'package:flutter_app/screens/verification_result_screen.dart';

Verification _verification({
  String verdict = 'REAL',
  String summary = 'A fact-checker rated the matching claim true.',
  List<String> findings = const ['A source rated the claim True.'],
  double confidence = 0.8,
}) => Verification(
  claim: 'The Earth revolves around the Sun.',
  verdict: verdict,
  confidence: confidence,
  summary: summary,
  findings: findings,
  createdAt: DateTime(2026, 1, 1),
);

List<VerificationSource> _sources() => [
  VerificationSource(
    verificationId: 0,
    name: 'Example Fact Checker',
    title: 'Earth orbits the Sun',
    url: 'https://example.org/fact-check',
  ),
];

Widget _explanationApp(
  Verification verification,
  List<VerificationSource> sources,
) => MaterialApp(
  home: FullExplanationScreen(verification: verification, sources: sources),
);

void main() {
  testWidgets(
    'REAL explanation displays claim, confidence, findings and source',
    (tester) async {
      final verification = _verification(
        findings: const ['First evidence finding.', 'Second evidence finding.'],
      );
      await tester.pumpWidget(_explanationApp(verification, _sources()));

      expect(find.text('REAL'), findsOneWidget);
      expect(find.text(verification.claim), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text(verification.summary), findsOneWidget);
      expect(find.text('First evidence finding.'), findsOneWidget);
      expect(find.text('Second evidence finding.'), findsOneWidget);
      expect(find.text('Example Fact Checker'), findsOneWidget);
      expect(find.text('Earth orbits the Sun'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('explanation-source-url-0')),
        findsOneWidget,
      );
      expect(
        find.textContaining('not the probability that the claim is true'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'FAKE verdict is presented without changing its evidence summary',
    (tester) async {
      const summary = 'Available fact-checks rated the claim false.';
      await tester.pumpWidget(
        _explanationApp(_verification(verdict: 'FAKE', summary: summary), []),
      );

      expect(find.text('FAKE'), findsOneWidget);
      expect(find.text(summary), findsOneWidget);
    },
  );

  testWidgets('UNCERTAIN summary is preserved without redundant note', (
    tester,
  ) async {
    const summary =
        "We couldn't find a fact-check that clearly rates this claim, so "
        "there isn't enough evidence to call it real or fake.";
    await tester.pumpWidget(
      _explanationApp(
        _verification(verdict: 'UNCERTAIN', summary: summary),
        [],
      ),
    );

    expect(find.text('UNCERTAIN'), findsOneWidget);
    expect(find.text(summary), findsOneWidget);
    expect(
      find.text(
        'The available evidence did not support a clear REAL or FAKE verdict.',
      ),
      findsNothing,
    );
  });

  testWidgets('UNCERTAIN fallback explains lack of a clear verdict only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _explanationApp(
        _verification(verdict: 'UNCERTAIN', summary: 'The evidence is mixed.'),
        [],
      ),
    );

    expect(
      find.text(
        'The available evidence did not support a clear REAL or FAKE verdict.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('fact-checkers disagree'), findsNothing);
  });

  testWidgets(
    'empty sources show the required message and empty fields are safe',
    (tester) async {
      await tester.pumpWidget(
        _explanationApp(
          _verification(
            summary: '',
            findings: const [],
            confidence: double.nan,
          ),
          [],
        ),
      );

      expect(find.text('No fact-checks found'), findsOneWidget);
      expect(find.text('No summary was provided.'), findsOneWidget);
      expect(find.text('No findings were provided.'), findsOneWidget);
      expect(find.text('Not available'), findsOneWidget);
    },
  );

  testWidgets('result button opens full explanation with existing data', (
    tester,
  ) async {
    final verification = _verification(
      verdict: 'FAKE',
      summary: 'The cited fact-check rated this claim false.',
      findings: const ['The fact-check directly addresses this claim.'],
    );
    final sources = _sources();
    await tester.pumpWidget(
      MaterialApp(
        home: VerificationResultScreen(
          verification: verification,
          sources: sources,
        ),
      ),
    );

    final explanationButton = find.text('View Full Explanation');
    await tester.ensureVisible(explanationButton);
    await tester.tap(explanationButton);
    await tester.pumpAndSettle();

    expect(find.text('Full Explanation'), findsOneWidget);
    expect(find.text(verification.claim), findsOneWidget);
    expect(find.text(verification.summary), findsOneWidget);
    expect(find.text(verification.findings.single), findsOneWidget);
    expect(find.text('Earth orbits the Sun'), findsOneWidget);
    expect(find.text('https://example.org/fact-check'), findsOneWidget);
    expect(find.textContaining('TF-IDF'), findsNothing);
    expect(find.textContaining('predict_proba'), findsNothing);
  });
}
