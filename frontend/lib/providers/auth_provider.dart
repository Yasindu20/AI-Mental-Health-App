import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.init();

      // Check if we have a valid token
      if (ApiService.hasToken) {
        // Try to verify the token by making a simple API call
        try {
          await ApiService.get('/profile/stats/');
          _isAuthenticated = true;
          _user = {'username': 'User'}; // Placeholder user data
        } catch (e) {
          // Token is invalid, clear it
          await ApiService.clearToken();
          _isAuthenticated = false;
          _user = null;
        }
      }
    } catch (e) {
      print('Auth init error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register
  Future<void> register(String username, String password, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await ApiService.register(username, password, email);
      _isAuthenticated = true;
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await ApiService.login(username, password);
      _isAuthenticated = true;
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _isAuthenticated = false;
      _user = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
