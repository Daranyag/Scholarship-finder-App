import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost on host machine
  // For physical device, this needs to be changed to the computer's LAN IP
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Backend error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Backend Unavailable', 'error': e.toString()};
    }
  }
}
