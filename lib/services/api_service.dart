import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 8);
  static Function()? onUnauthorized;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'bypass-tunnel-reminder': 'true',
      'User-Agent': 'GarageApp/1.0 Mobile',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(url, headers: await _getHeaders()).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(url, headers: await _getHeaders(), body: jsonEncode(body)).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.patch(url, headers: await _getHeaders(), body: jsonEncode(body)).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(url, headers: await _getHeaders(), body: jsonEncode(body)).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(url, headers: await _getHeaders()).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('$e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.trim();
      if (body.isEmpty) return null;
      if (body.startsWith('{') || body.startsWith('[')) {
        return jsonDecode(body);
      }
      throw Exception('Localtunnel returned HTML landing page. Please open https://kaushik-garage.loca.lt once in browser!');
    } else if (response.statusCode == 401) {
      SharedPreferences.getInstance().then((prefs) => prefs.remove('token'));
      onUnauthorized?.call();
      throw Exception('Session expired (401 Unauthorized). Please log in again.');
    } else {
      String msg = 'Server error (HTTP ${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map && errJson.containsKey('message')) {
          msg = '${errJson['message']} (${response.statusCode})';
        } else {
          msg = '${response.body} (${response.statusCode})';
        }
      } catch (_) {
        msg = '${response.body} (${response.statusCode})';
      }
      throw Exception(msg);
    }
  }
}
