import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Centralised HTTP helper.
/// Reads the token from AuthService first; if that returns null it falls
/// back to SharedPreferences so hot-reload / web sessions don't break.
class ApiHelper {
  static const base = 'https://josephkiarie2.pythonanywhere.com/api';

  static Future<String?> _token() async {
    // Try in-memory first
    final t = AuthService.getToken();
    if (t != null && t.isNotEmpty) return t;
    // Fall back to prefs (survives hot-reload on web)
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ??
        prefs.getString('access_token') ??
        prefs.getString('auth_token');
  }

  static Future<Map<String, String>> headers() async {
    final t = await _token();
    return {
      'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  static Future<http.Response> get(String path) async {
    final h = await headers();
    return http.get(Uri.parse('$base$path'), headers: h);
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final h = await headers();
    return http.post(Uri.parse('$base$path'),
        headers: h, body: jsonEncode(body));
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final h = await headers();
    return http.patch(Uri.parse('$base$path'),
        headers: h, body: jsonEncode(body));
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final h = await headers();
    return http.put(Uri.parse('$base$path'),
        headers: h, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path) async {
    final h = await headers();
    return http.delete(Uri.parse('$base$path'), headers: h);
  }
}