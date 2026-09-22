import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;
  static final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  // Helper to safely format responses
  static Map<String, dynamic> _formatResponse(http.Response response) {
    try {
      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response: ${response.statusCode}'
      };
    }
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? dateOfBirth,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'name': name,
              'email': email,
              'password': password,
              'phone': phone ?? '',
              if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return _formatResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: Unable to register'};
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = _formatResponse(response);
      if (data['success'] == true && data['token'] != null) {
        await saveToken(data['token']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: Unable to login'};
    }
  }

  // Get Current User
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      return _formatResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: Unable to fetch user'};
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        // Inform backend (best effort)
        await http
            .post(
              Uri.parse('$baseUrl/auth/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      // Ignore network errors on logout, we just clear local state anyway
    } finally {
      await deleteToken();
    }
  }

  // --- Token Management ---
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
