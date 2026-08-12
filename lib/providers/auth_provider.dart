import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _error   = '';
  String? _token;
  String? _staffName = 'Suresh';
  String? _garageName = 'Shree Auto Garage';

  bool    get isLoading  => _isLoading;
  String  get error      => _error;
  String? get token      => _token;
  String? get staffName  => _staffName;
  String? get garageName => _garageName;

  /// Call once on app start to restore a saved token.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error     = '';
    notifyListeners();

    try {
      final tok = await _authService.login(email, password);
      _token     = tok;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error     = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    notifyListeners();
  }
}
