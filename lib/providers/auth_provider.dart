import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  checking,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.checking;
  Map<String, dynamic>? _user;

  AuthStatus get status => _status;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    checkToken();
  }

  Future<void> checkToken() async {
    _status = AuthStatus.checking;
    notifyListeners();

    final token = await AuthService.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Verify token with backend
    final response = await AuthService.getMe();
    if (response['success'] == true) {
      _user = response['user'];
      _status = AuthStatus.authenticated;
    } else {
      // Token is invalid or expired
      await AuthService.deleteToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final response = await AuthService.login(email: email, password: password);
    if (response['success'] == true) {
      _user = response['user'];
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  // Directly set auth state after manual registration
  void setAuthenticated(Map<String, dynamic> user) {
    _user = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
