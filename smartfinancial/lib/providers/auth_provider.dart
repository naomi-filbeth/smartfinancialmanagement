import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../providers/sales_provider.dart'; // Import SalesProvider

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userName;
  bool _rememberMe = false;
  final AuthService _authService = AuthService();

  AuthProvider() {
    _loadPreferences();
  }

  String? get userName => _userName;
  bool get isAuthenticated => _token != null;
  bool get rememberMe => _rememberMe;

  Future<void> register(String username, String email, String password) async {
    final result = await _authService.register(username, email, password);
    if (!result['success']) {
      throw Exception(result['message']);
    }
    notifyListeners();
  }

  Future<void> login(String username, String password, bool rememberMe, SalesProvider salesProvider) async {
    final result = await _authService.login(username, password);
    if (result['success']) {
      _token = result['token'];
      _userName = username;
      _rememberMe = rememberMe;
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_name', username);
        await prefs.setBool('remember_me', true);
      }
      // Set the user in SalesProvider with username and token
      await salesProvider.setUser(username, _token!);
      notifyListeners();
    } else {
      throw Exception(result['message']);
    }
  }

  Future<void> logout(SalesProvider salesProvider) async {
    // Clear SalesProvider data
    await salesProvider.clearUser();
    _token = null;
    _userName = null;
    final prefs = await SharedPreferences.getInstance();
    if (!_rememberMe) {
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('remember_me');
    }
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    final result = await _authService.resetPassword(email);
    if (!result['success']) {
      throw Exception(result['message']);
    }
    notifyListeners();
  }

  Future<bool> checkAuthentication(SalesProvider salesProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final url = '${_authService.baseUrl}/validate-token/';
    print('Validate Token URL: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('Validate Token Response: ${response.statusCode} ${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _token = token;
        _userName = prefs.getString('user_name');
        // Set the user in SalesProvider with username and token
        if (_userName != null) {
          await salesProvider.setUser(_userName!, _token!);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Validate Token Error: $e');
      return false;
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('remember_me') ?? false;
    notifyListeners();
  }
}