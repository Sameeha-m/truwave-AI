import 'dart:convert';

import 'package:http/http.dart' as http;

class VerificationService {
  static const String baseUrl = String.fromEnvironment(
    'TRUWAVE_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  Future<Map<String, dynamic>> verifyClaim(String claim) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'claim': claim}),
    );

    if (response.statusCode != 200) {
      throw Exception('Verification request failed');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
