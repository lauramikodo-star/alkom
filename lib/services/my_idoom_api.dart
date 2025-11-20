import 'dart:convert';
import 'package:http/http.dart' as http;

class MyIdoomApi {
  static const String _baseUrl = 'https://myidoom.at.dz/api';

  // Headers mimicking a real browser/app to avoid blocking
  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'User-Agent': 'Dart/3.0 (dart:io)',
    'Accept': 'application/json',
    'Accept-Encoding': 'gzip',
  };

  /// Login to MyIdoom
  /// Returns a Map with token and user info if successful.
  Future<Map<String, dynamic>> login(String nd, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login_new');
    final body = json.encode({
      "nd": nd,
      "password": password,
      "lang": "fr"
    });

    try {
      final response = await http.post(url, headers: _baseHeaders, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {
          'error': true,
          'message': 'Login failed: ${response.statusCode}',
          'details': response.body
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Register Step 1
  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    // data should contain: nd, ncli, mobile, email, password, password_confirmation, lang
    final body = json.encode(data);

    try {
      final response = await http.post(url, headers: _baseHeaders, body: body);
      final responseBody = json.decode(response.body);
      return responseBody;
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Register Step 2 (Confirm with OTP)
  Future<Map<String, dynamic>> confirmRegister(String nd, String otp) async {
    final url = Uri.parse('$_baseUrl/auth/confirmRegister');
    final body = json.encode({
      "nd": nd,
      "otp": otp
    });

    try {
      final response = await http.post(url, headers: _baseHeaders, body: body);
      final responseBody = json.decode(response.body);
      return responseBody;
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Get Account Information
  /// Requires Bearer Token
  Future<Map<String, dynamic>> getAccountInfo(String token) async {
    final url = Uri.parse('$_baseUrl/compte');
    final headers = {
      ..._baseHeaders,
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
         // The API usually returns a JSON structure.
         // We handle cases where it might be text or wrapped.
         try {
            return json.decode(response.body);
         } catch (e) {
            return {'error': true, 'message': 'Failed to parse JSON', 'raw': response.body};
         }
      } else {
        return {
          'error': true,
          'statusCode': response.statusCode,
          'message': 'Failed to fetch account info'
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'Network error: $e'};
    }
  }

  /// Check header/login status (Alternative if needed)
  Future<Map<String, dynamic>> checkHeaderLogin(String token) async {
     final url = Uri.parse('$_baseUrl/checkHeader/login');
     final headers = {
      ..._baseHeaders,
      'Authorization': 'Bearer $token',
    };
     try {
      final response = await http.get(url, headers: headers);
      return json.decode(response.body);
     } catch(e) {
       return {'error': true, 'message': '$e'};
     }
  }
}
