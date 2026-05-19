import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Centralised HTTP helper.
/// Handles:
/// - Token retrieval
/// - Headers
/// - GET / POST / PATCH / PUT / DELETE requests
/// - Automatic redirect to LoginScreen on 401
class ApiHelper {
  static const String base =
      'https://josephkiarie2.pythonanywhere.com/api';

  /// Navigator key — set this in main.dart so we can navigate without context
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Internal token getter
  static Future<String?> _token() async {
    final t = AuthService.getToken();
    if (t != null && t.isNotEmpty) return t;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ??
        prefs.getString('access_token') ??
        prefs.getString('auth_token');
  }

  /// Public token getter
  static Future<String?> getToken() async => await _token();

  /// Default headers
  static Future<Map<String, String>> headers() async {
    final t = await _token();
    return {
      'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  /// Called whenever a 401 is received — clears auth and navigates to login
  static Future<void> _handle401() async {
    await AuthService.logout();

    final nav = navigatorKey?.currentState;
    if (nav == null) return;

    // Lazy import to avoid circular dependency
    // We push a named route OR use the navigator key to replace the stack
    nav.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  /// Check response for 401 and handle it
  static Future<http.Response> _checked(http.Response res) async {
    if (res.statusCode == 401) {
      await _handle401();
    }
    return res;
  }

  /// GET request
  static Future<http.Response> get(String path) async {
    final h = await headers();
    final res = await http.get(Uri.parse('$base$path'), headers: h);
    return _checked(res);
  }

  /// POST request
  static Future<http.Response> post(
      String path, Map<String, dynamic> body) async {
    final h = await headers();
    final res = await http.post(Uri.parse('$base$path'),
        headers: h, body: jsonEncode(body));
    return _checked(res);
  }

  /// PATCH request
  static Future<http.Response> patch(
      String path, Map<String, dynamic> body) async {
    final h = await headers();
    final res = await http.patch(Uri.parse('$base$path'),
        headers: h, body: jsonEncode(body));
    return _checked(res);
  }

  /// PUT request
  static Future<http.Response> put(
      String path, Map<String, dynamic> body) async {
    final h = await headers();
    final res = await http.put(Uri.parse('$base$path'),
        headers: h, body: jsonEncode(body));
    return _checked(res);
  }

  /// DELETE request
  static Future<http.Response> delete(String path) async {
    final h = await headers();
    final res = await http.delete(Uri.parse('$base$path'), headers: h);
    return _checked(res);
  }
}