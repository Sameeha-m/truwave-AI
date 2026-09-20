import 'dart:convert';

import 'package:http/http.dart' as http;

class VerificationService {
  Future<Map<String, dynamic>> verifyClaim(String claim) async {
    final response = await http.post(
      Uri.parse('http://YOUR_FASTAPI_URL/verify'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'claim': claim,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Verification request failed');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}