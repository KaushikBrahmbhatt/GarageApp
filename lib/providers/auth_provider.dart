import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _error   = '';
  String? _token;
  String? _staffName;   // BUG-08 fix: dynamic, not hardcoded
  String? _garageName;  // BUG-08 fix: dynamic, not hardcoded

  bool    get isLoading  => _isLoading;
  String  get error      => _error;
  String? get token      => _token;
  String? get staffName  => _staffName;
  String? get garageName => _garageName;

  /// Call once on app start to restore a saved token and user info.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token      = prefs.getString('token');
    _staffName  = prefs.getString('staff_name');   // BUG-08 fix
    _garageName = prefs.getString('garage_name');  // BUG-08 fix
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error     = '';
    notifyListeners();

    try {
      final tok = await _authService.login(email, password);
      _token = tok;

      // BUG-08 fix: load name/garage from SharedPreferences written by AuthService
      final prefs = await SharedPreferences.getInstance();
      _staffName  = prefs.getString('staff_name');
      _garageName = prefs.getString('garage_name');

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

  Future<void> updateGarageName(String newGarageName) async {
    _garageName = newGarageName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('garage_name', newGarageName);
    notifyListeners();
  }

  Future<void> updateStaffName(String newStaffName) async {
    _staffName = newStaffName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('staff_name', newStaffName);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _token      = null;
    _staffName  = null;
    _garageName = null;
    notifyListeners();
  }
}
