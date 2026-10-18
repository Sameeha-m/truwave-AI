import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_app/services/verification_service.dart';

void main() {
  test('accepts the shared verification response shape', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/verify');
      expect(jsonDecode(request.body), {'claim': 'A claim'});
      return http.Response(
        jsonEncode({
          'verdict': 'UNCERTAIN',
          'confidence': 0.5,
          'summary': 'Not enough evidence.',
          'findings': <String>[],
          'sources': <Map<String, String>>[],
        }),
        200,
      );
    });

    final response = await VerificationService(client: client).verifyClaim('A claim');
    expect(response['verdict'], 'UNCERTAIN');
  });

  test('rejects non-success responses without exposing the body', () async {
    final client = MockClient((_) async => http.Response('private upstream detail', 503));
    await expectLater(
      VerificationService(client: client).verifyClaim('A claim'),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects malformed and contract-invalid JSON', () async {
    for (final body in ['not json', '{"verdict":"MADE_UP"}']) {
      final client = MockClient((_) async => http.Response(body, 200));
      await expectLater(
        VerificationService(client: client).verifyClaim('A claim'),
        throwsA(anyOf(isA<FormatException>(), isA<TypeError>())),
      );
    }
  });

  test('times out a stalled request', () async {
    final completer = Completer<http.Response>();
    final client = MockClient((_) => completer.future);
    await expectLater(
      VerificationService(
        client: client,
        requestTimeout: const Duration(milliseconds: 10),
      ).verifyClaim('A claim'),
      throwsA(isA<TimeoutException>()),
    );
  });
}
