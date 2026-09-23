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

  // GET /api/scholarships/matches (Module 10E)
  static Future<Map<String, dynamic>> getMatches() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/scholarships/matches'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to load scholarship matches'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred: $e'};
    }
  }

  // GET /api/scholarships/search
  static Future<Map<String, dynamic>> searchScholarships(Map<String, dynamic> params) async {
    try {
      final token = await AuthService.getToken();
      
      final queryParams = <String, String>{};
      params.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          queryParams[key] = value.toString();
        }
      });
      
      final uri = Uri.parse('$baseUrl/scholarships/search').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Search failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
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

  // Toggle bookmark (POST / DELETE /api/scholarships/:id/bookmark)
  static Future<Map<String, dynamic>> toggleBookmark(String id, bool isCurrentlyBookmarked) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'message': 'No token'};

      final uri = Uri.parse('$baseUrl/scholarships/$id/bookmark');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      http.Response response;
      if (isCurrentlyBookmarked) {
        response = await http.delete(uri, headers: headers);
      } else {
        response = await http.post(uri, headers: headers);
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to toggle bookmark'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Analyze URL
  static Future<Map<String, dynamic>> analyzeUrl(String url) async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse('$baseUrl/scholarships/analyze-url'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode({'url': url}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final decoded = json.decode(response.body);
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to analyze URL: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Check Eligibility
  static Future<Map<String, dynamic>> checkEligibility(String id, Map<String, dynamic> body) async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse('$baseUrl/scholarships/$id/check-eligibility'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final decoded = json.decode(response.body);
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to check eligibility: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Universal Analyze (Module 11)
  static Future<Map<String, dynamic>> analyzeUniversal({
    required String sourceType,
    String? url,
    String? filePath,
  }) async {
    try {
      final token = await AuthService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/scholarships/universal-analyze'),
      );
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['sourceType'] = sourceType;
      
      if (sourceType == 'url' && url != null) {
        request.fields['url'] = url;
      } else if ((sourceType == 'pdf' || sourceType == 'image') && filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      } else {
        return {'success': false, 'message': 'Invalid inputs for $sourceType'};
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final decoded = json.decode(response.body);
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to analyze: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred: $e'};
    }
  }

  // --- APPLICATION TRACKING (Module 10G) ---

  static Future<Map<String, dynamic>> getApplications() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/applications'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to load applications'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  static Future<Map<String, dynamic>> createApplication(Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/applications'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to create tracking record'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  static Future<Map<String, dynamic>> updateApplication(String id, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/applications/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to update tracking record'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  static Future<Map<String, dynamic>> deleteApplication(String id) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/applications/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to delete tracking record'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // --- DATA & FETCHING MONITOR (Module 10I) ---

  static Future<Map<String, dynamic>> getDataMonitorOverview() async {
    return _authenticatedGetRequest('/data-monitor/overview');
  }

  static Future<Map<String, dynamic>> getDataMonitorSources() async {
    return _authenticatedGetRequest('/data-monitor/sources');
  }

  static Future<Map<String, dynamic>> getDataMonitorFetchHistory() async {
    return _authenticatedGetRequest('/data-monitor/fetch-history');
  }

  static Future<Map<String, dynamic>> getDataMonitorRecentChanges() async {
    return _authenticatedGetRequest('/data-monitor/changes');
  }

  static Future<Map<String, dynamic>> refreshDataMonitor() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/data-monitor/refresh'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 202 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to trigger refresh'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Generic authenticated GET helper
  static Future<Map<String, dynamic>> _authenticatedGetRequest(String endpoint) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed request: ${response.statusCode}'};
      }
    } catch (e) {
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // GET /api/scholarships/:id/readiness
  static Future<Map<String, dynamic>> getApplicationReadiness(String scholarshipId) async {
    return await _authenticatedGetRequest('/scholarships/$scholarshipId/readiness');
  }

  // POST /api/scholarships/:id/documents/upload
  static Future<Map<String, dynamic>> uploadScholarshipDocument(String scholarshipId, String documentName, String filePath) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('$baseUrl/scholarships/$scholarshipId/documents/upload');

      var request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['documentName'] = documentName;
      request.files.add(await http.MultipartFile.fromPath('document', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final jsonResponse = json.decode(response.body);

      // Map 400 errors directly so the frontend logic can use errorType
      if (response.statusCode == 200 || response.statusCode == 400) {
        return jsonResponse;
      }
      return {'success': false, 'message': 'Upload failed: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred during upload'};
    }
  }

  // --- Settings & Account Management ---

  static Future<Map<String, dynamic>> getSettings() async {
    return await _authenticatedGetRequest('/settings');
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/settings'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to update settings'};
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/settings/change-password'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword
        }),
      ).timeout(const Duration(seconds: 15));

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  static Future<Map<String, dynamic>> exportData() async {
    return await _authenticatedGetRequest('/settings/export');
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/settings/account'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }
}
