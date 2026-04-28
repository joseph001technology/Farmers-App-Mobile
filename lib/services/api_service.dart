import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screens/login_screen.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl =
      "https://josephkiarie2.pythonanywhere.com/api";

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Map<String, String> get headers {
    final token = AuthService.getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static void _handle401() async {
    await AuthService.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // GET
  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );

    if (response.statusCode == 401) {
      _handle401();
      throw Exception("Session expired. Please login again.");
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("GET $endpoint failed: ${response.statusCode}");
  }

  // POST
  static Future<http.Response> post(String endpoint, dynamic body) async {
    final response = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      _handle401();
    }

    return response;
  }

  // PUT
  static Future<http.Response> put(String endpoint, dynamic body) async {
    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      _handle401();
    }

    return response;
  }

  // DELETE
  static Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );

    if (response.statusCode == 401) {
      _handle401();
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Delete failed: ${response.statusCode}");
    }

    return response;
  }
}