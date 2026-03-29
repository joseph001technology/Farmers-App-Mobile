import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static String? accessToken;
  static String? refreshToken;
  static String? username;
  static String? phoneNumber;
  static String? role;

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
      return true;
    }
    return false;
  }

  // Register
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

  static void logout() {
    accessToken = null;
    refreshToken = null;
    username = null;
    phoneNumber = null;
    role = null;
  }
}