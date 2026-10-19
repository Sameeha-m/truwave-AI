import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_app/screens/verification_loading_screen.dart';
import 'package:flutter_app/services/verification_service.dart';

const _claim = 'The Earth revolves around the Sun';

Map<String, dynamic> _responseBody() => {
  'verdict': 'REAL',
  'confidence': 0.8,
  'summary': 'Fact-checkers rated this claim true.',
  'findings': ['A fact-checker rated the matching claim True.'],
  'sources': [
    {
      'name': 'Example Fact Checker',
      'title': 'Earth orbits the Sun',
      'url': 'https://example.org/fact-check',
    },
  ],
};

Widget _loadingApp(VerificationService service) => MaterialApp(
  home: VerificationLoadingScreen(
    claim: _claim,
    verificationService: service,
    saveVerification: (_, _) async {},
  ),
);

Widget _appWithStartButton(VerificationService service) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => VerificationLoadingScreen(
                claim: _claim,
                verificationService: service,
                saveVerification: (_, _) async {},
              ),
            ),
          ),
          child: const Text('Start verification'),
        ),
      ),
    ),
  ),
);

Widget _appWithSaveFailure(VerificationService service) => MaterialApp(
  home: VerificationLoadingScreen(
    claim: _claim,
    verificationService: service,
    saveVerification: (_, _) async => throw StateError('database unavailable'),
  ),
);

void main() {
  testWidgets('steps animate to the final stage and wait for POST /verify', (
    tester,
  ) async {
    final responseCompleter = Completer<http.Response>();
    late http.Request capturedRequest;
    final client = MockClient((request) {
      capturedRequest = request;
      return responseCompleter.future;
    });
    await tester.pumpWidget(_loadingApp(VerificationService(client: client)));
    expect(
      find.text('Finding reliable sources'),
      findsOneWidget,
      reason:
          'loading=${find.text('Verification in progress').evaluate().length}, '
          'error=${find.text('Verification failed. Check your connection and retry.').evaluate().length}',
    );
    expect(find.text('Comparing evidence'), findsOneWidget);
    expect(find.text('Preparing explanation'), findsOneWidget);
    expect(find.text('Finalizing result'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
    expect(find.text('Verification in progress'), findsOneWidget);

    // The final visual step can remain active; it never reports an error while
    // the real request is still pending.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Verification in progress'), findsOneWidget);
    expect(
      find.text('Verification failed. Check your connection and retry.'),
      findsNothing,
    );

    responseCompleter.complete(http.Response(jsonEncode(_responseBody()), 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 600));

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/verify');
    expect(jsonDecode(capturedRequest.body), {'claim': _claim});
    expect(find.text('Verification Result'), findsOneWidget);
    expect(find.text('REAL'), findsOneWidget);
    expect(find.text('Confidence in this classification'), findsOneWidget);
    expect(find.text('Fact-checkers rated this claim true.'), findsOneWidget);
    expect(find.text('A fact-checker rated the matching claim True.'), findsOneWidget);
    expect(find.text('Earth orbits the Sun'), findsOneWidget);
  });

  for (final verdict in ['FAKE', 'UNCERTAIN']) {
    testWidgets('$verdict response is rendered as returned', (tester) async {
      final body = _responseBody()
        ..['verdict'] = verdict
        ..['summary'] = '$verdict explanation from backend'
        ..['findings'] = ['$verdict evidence finding'];
      final client = MockClient(
        (_) async => http.Response(jsonEncode(body), 200),
      );
      await tester.pumpWidget(
        _appWithStartButton(VerificationService(client: client)),
      );
      await tester.tap(find.text('Start verification'));
      await tester.pumpAndSettle();

      expect(find.text(verdict), findsOneWidget);
      expect(find.text('$verdict explanation from backend'), findsOneWidget);
      expect(find.text('$verdict evidence finding'), findsOneWidget);
      expect(find.text('Earth orbits the Sun'), findsOneWidget);
    });
  }

  testWidgets('still shows a real verification result when local save fails', (
    tester,
  ) async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode(_responseBody()), 200),
    );
    await tester.pumpWidget(
      _appWithSaveFailure(VerificationService(client: client)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Verification Result'), findsOneWidget);
    expect(find.text('REAL'), findsOneWidget);
    expect(
      find.text('Verification completed, but this result could not be saved.'),
      findsOneWidget,
    );
  });

  testWidgets('early successful response advances to final and opens result', (
    tester,
  ) async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode(_responseBody()), 200),
    );
    await tester.pumpWidget(
      _appWithStartButton(VerificationService(client: client)),
    );
    await tester.tap(find.text('Start verification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Verification Result'), findsOneWidget);
    expect(find.text('REAL'), findsOneWidget);
  });

  testWidgets('failed POST /verify stops loading and shows existing error', (
    tester,
  ) async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('unavailable', 503);
    });
    await tester.pumpWidget(
      _appWithStartButton(VerificationService(client: client)),
    );
    await tester.tap(find.text('Start verification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Start verification'), findsOneWidget);
    expect(find.text('Verification in progress'), findsNothing);
    expect(
      find.text('Verification failed. Check your connection and retry.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Start verification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(requests, 2, reason: 'the user can retry from the claim form');
  });

  testWidgets('an empty source list is accepted and shown as a real result', (
    tester,
  ) async {
    final body = _responseBody()..['sources'] = <Map<String, String>>[];
    final client = MockClient(
      (_) async => http.Response(jsonEncode(body), 200),
    );
    await tester.pumpWidget(
      _appWithStartButton(VerificationService(client: client)),
    );
    await tester.tap(find.text('Start verification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Verification Result'), findsOneWidget);
    expect(find.text('REAL'), findsOneWidget);
    expect(find.text('Earth orbits the Sun'), findsNothing);
  });
}
