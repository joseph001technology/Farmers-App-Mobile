import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Centralised HTTP helper.
/// Handles:
/// - Token retrieval
/// - Headers
/// - GET / POST / PATCH / PUT / DELETE requests
class ApiHelper {
  static const String base =
      'https://josephkiarie2.pythonanywhere.com/api';

  /// Internal token getter
  static Future<String?> _token() async {
    // Try AuthService memory token first
    final t = AuthService.getToken();

    if (t != null && t.isNotEmpty) {
      return t;
    }

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token') ??
        prefs.getString('access_token') ??
        prefs.getString('auth_token');
  }

  /// Public token getter
  static Future<String?> getToken() async {
    return await _token();
  }

  /// Default headers
  static Future<Map<String, String>> headers() async {
    final t = await _token();

    return {
      'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty)
        'Authorization': 'Bearer $t',
    };
  }

  /// GET request
  static Future<http.Response> get(String path) async {
    final h = await headers();

    return await http.get(
      Uri.parse('$base$path'),
      headers: h,
    );
  }

  /// POST request
  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final h = await headers();

    return await http.post(
      Uri.parse('$base$path'),
      headers: h,
      body: jsonEncode(body),
    );
  }

  /// PATCH request
  static Future<http.Response> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final h = await headers();

    return await http.patch(
      Uri.parse('$base$path'),
      headers: h,
      body: jsonEncode(body),
    );
  }

  /// PUT request
  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final h = await headers();

    return await http.put(
      Uri.parse('$base$path'),
      headers: h,
      body: jsonEncode(body),
    );
  }

  /// DELETE request
  static Future<http.Response> delete(String path) async {
    final h = await headers();

    return await http.delete(
      Uri.parse('$base$path'),
      headers: h,
    );
  }
}