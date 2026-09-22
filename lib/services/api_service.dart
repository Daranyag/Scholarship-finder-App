import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      
      // Handle specific HTTP status codes
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 400 || 
                 response.statusCode == 401 || 
                 response.statusCode == 404 || 
                 response.statusCode == 500) {
        return {
          'success': false, 
          'message': 'Backend error: ${response.statusCode}'
        };
      } else {
        return {
          'success': false, 
          'message': 'Unexpected HTTP status: ${response.statusCode}'
        };
      }
    } catch (e) {
      // Handle timeout and network errors
      return {
        'success': false, 
        'message': 'Backend Unavailable', 
        'error': e.toString()
      };
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'success': false,
        'message': 'Failed to load profile: ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: Unable to fetch profile'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'success': false,
        'message': 'Failed to update profile: ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: Unable to update profile'};
    }
  }

  // Get all scholarships
  static Future<Map<String, dynamic>> getScholarships() async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/scholarships'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to load scholarships: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Get scholarship matches
  static Future<Map<String, dynamic>> getMatches() async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/scholarships/matches'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to load matches: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Get scholarship by ID
  static Future<Map<String, dynamic>> getScholarshipById(String id) async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/scholarships/$id'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Scholarship not found'};
      }
      return {'success': false, 'message': 'Failed to load scholarship details: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }
}
