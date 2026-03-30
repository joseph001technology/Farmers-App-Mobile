import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? accessToken;
  static String? refreshToken;
  static String? username;
  static String? phoneNumber;
  static String? role;
  static String? profilePhoto;     // ← Added for profile photo support

  // Login
  static Future<bool> login(String phoneNumber, String password) async {
    final response = await http.post(
      Uri.parse("https://josephkiarie2.pythonanywhere.com/api/users/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phoneNumber,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      accessToken = data['access'];
      refreshToken = data['refresh'];
      username = data['username'];
      AuthService.phoneNumber = data['phone_number'];
      role = data['role'];

      // Save profile photo if it comes in login response
      if (data['profile'] != null && data['profile']['profile_photo'] != null) {
        profilePhoto = data['profile']['profile_photo'];
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access', accessToken ?? '');
      await prefs.setString('refresh', refreshToken ?? '');
      await prefs.setString('username', username ?? '');
      await prefs.setString('phoneNumber', AuthService.phoneNumber ?? '');
      await prefs.setString('role', role ?? '');
      if (profilePhoto != null) {
        await prefs.setString('profilePhoto', profilePhoto!);
      }

      return true;
    }
    return false;
  }

  // Register (your existing method)
  static Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String username,
    required String password,
    String role = 'customer',
  }) async {
    final response = await http.post(
      Uri.parse("https://josephkiarie2.pythonanywhere.com/api/users/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phoneNumber,
        "username": username,
        "password": password,
        "role": role,
      }),
    );

    return {
      "success": response.statusCode == 201,
      "data": jsonDecode(response.body),
    };
  }

  static String? getToken() => accessToken;

  static bool isLoggedIn() => accessToken != null;

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    accessToken = null;
    refreshToken = null;
    username = null;
    phoneNumber = null;
    role = null;
    profilePhoto = null;
  }

  // Load saved data when app starts (optional but useful)
  static Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access');
    refreshToken = prefs.getString('refresh');
    username = prefs.getString('username');
    phoneNumber = prefs.getString('phoneNumber');
    role = prefs.getString('role');
    profilePhoto = prefs.getString('profilePhoto');
  }
}