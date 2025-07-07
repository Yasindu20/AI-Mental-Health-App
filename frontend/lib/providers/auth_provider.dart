import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  // Initialize
  Future<void> init() async {
    await ApiService.init();
    // You could check if session is valid here
  }

  // Register
  Future<void> register(String username, String password, String email) async {
    try {
      _user = await ApiService.register(username, password, email);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      rethrow;
    }
  }

  // Login
  Future<void> login(String username, String password) async {
    try {
      _user = await ApiService.login(username, password);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await ApiService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
