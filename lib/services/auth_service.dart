import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Returns the plain-text Sanctum token on success, throws on failure.
  Future<String> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final token = data['token'] as String?;
    if (token == null) throw Exception('Login failed: no token returned.');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    // Persist garage + staff info for offline display
    if (data['garage'] != null) {
      await prefs.setString('garage_name', data['garage']['name'] ?? '');
    }
    if (data['staff'] != null) {
      await prefs.setString('staff_name', data['staff']['name'] ?? '');
      await prefs.setString('staff_role', data['staff']['role'] ?? '');
    }

    return token;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
