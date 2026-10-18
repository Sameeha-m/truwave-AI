import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class VerificationService {
  final http.Client? _client;
  final Duration requestTimeout;

  VerificationService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _client = client;

  static const String baseUrl = String.fromEnvironment(
    'TRUWAVE_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  Future<Map<String, dynamic>> verifyClaim(String claim) async {
    final uri = Uri.parse('$baseUrl/verify');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'claim': claim});
    final response = await (_client == null
            ? http.post(uri, headers: headers, body: body)
            : _client!.post(uri, headers: headers, body: body))
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Verification request failed');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected verification response');
    }

    final verdict = decoded['verdict'];
    final confidence = decoded['confidence'];
    final summary = decoded['summary'];
    final findings = decoded['findings'];
    final sources = decoded['sources'];
    if (!const {'REAL', 'FAKE', 'UNCERTAIN'}.contains(verdict) ||
        confidence is! num ||
        !confidence.isFinite ||
        confidence < 0 ||
        confidence > 1 ||
        summary is! String ||
        findings is! List ||
        findings.any((finding) => finding is! String) ||
        sources is! List ||
        sources.any((source) =>
            source is! Map<String, dynamic> ||
            source['name'] is! String ||
            source['title'] is! String ||
            source['url'] is! String)) {
      throw const FormatException('Unexpected verification response');
    }

    return decoded;
  }
}
