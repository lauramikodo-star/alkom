import 'dart:convert';
import 'package:http/http.dart' as http;

class MyIdoomApi {
  static const String _baseUrl = 'https://myidoom.at.dz';

  // Using the same Basic Auth as the payment API, as they likely share the gateway.
  static const Map<String, String> _baseHeaders = {
    'Authorization': 'Basic VEdkNzJyOTozUjcjd2FiRHNfSGpDNzg3IQ==',
    'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 10; vivo X21A Build/QD4A.200805.003)',
    'Content-Type': 'application/json; charset=UTF-8', // JSON is common for modern APIs
    'Connection': 'Keep-Alive',
    'Accept-Encoding': 'gzip',
  };

  String? _sessionCookie;

  void setSessionCookie(String? cookie) {
    _sessionCookie = cookie;
  }

  Future<Map<String, dynamic>> login(String nd, String password) async {
    final uri = Uri.parse('$_baseUrl/api/checkHeader/login');

    // Try JSON body first
    final body = jsonEncode({
      'nd': nd,
      'password': password,
    });

    try {
      final response = await http.post(
        uri,
        headers: _baseHeaders,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Extract cookie
        final cookie = response.headers['set-cookie'];
        if (cookie != null) {
          _sessionCookie = cookie;
        }

        return {
          'success': true,
          'data': jsonDecode(response.body),
          'cookie': cookie,
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusCode}',
          'body': response.body
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAccountInfo() async {
    if (_sessionCookie == null) {
      return {'success': false, 'message': 'Not logged in'};
    }

    final uri = Uri.parse('$_baseUrl/api/compte');
    final headers = Map<String, String>.from(_baseHeaders);
    headers['Cookie'] = _sessionCookie!;
    // Remove Content-Type for GET requests or keep it, usually fine.

    try {
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
         return {
          'success': false,
          'message': 'Failed to fetch info: ${response.statusCode}',
          'body': response.body
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
