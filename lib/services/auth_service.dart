import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ─── Base URL ──────────────────────────────────────────────────────────────
  static const String _base =
      'https://josephkiarie2.pythonanywhere.com/api/users';

  // ─── In-memory state ───────────────────────────────────────────────────────
  static String? accessToken;
  static String? refreshToken;
  static String? username;
  static String? phoneNumber;
  static String? role;
  static String? profilePhoto;

  // ─── Phone formatter ───────────────────────────────────────────────────────
  static String formatPhone(String phone) {
    phone = phone.trim();
    if (phone.startsWith('+254')) return phone.replaceFirst('+', '');
    if (phone.startsWith('0')) return '254${phone.substring(1)}';
    return phone;
  }

  // ─── Error parser ─────────────────────────────────────────────────────────
  static String _parseError(dynamic data) {
    if (data == null) return 'Unknown error';
    if (data is String) return data;
    if (data is Map) {
      final first = data.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    return 'Registration failed';
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  /// Returns {"success": bool, "data": Map, "message": String?}
  static Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String username,
    required String email,        // ← required by your serializer
    required String password,
    String role = 'customer',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_base/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': formatPhone(phoneNumber),
          'username': username,
          'email': email,
          'role': role,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'data': data,
          'message': _parseError(data),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  /// Returns {"success": bool, "message": String?}
  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_base/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': formatPhone(phone),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        accessToken = data['access'];
        refreshToken = data['refresh'];
        username = data['username'];
        AuthService.phoneNumber = data['phone_number'];
        role = data['role'];

        if (data['profile'] != null &&
            data['profile']['profile_photo'] != null) {
          profilePhoto = data['profile']['profile_photo'];
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access', accessToken ?? '');
        await prefs.setString('refresh', refreshToken ?? '');
        await prefs.setString('username', username ?? '');
        await prefs.setString('phoneNumber', AuthService.phoneNumber ?? '');
        await prefs.setString('role', role ?? '');
        if (profilePhoto != null) {
          await prefs.setString('profilePhoto', profilePhoto!);
        }

        return {'success': true};
      } else {
        return {
          'success': false,
          'message': _parseError(data),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Token refresh ────────────────────────────────────────────────────────
  static Future<bool> refreshAccessToken() async {
    if (refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_base/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        accessToken = data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access', accessToken!);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String? getToken() => accessToken;
  static bool isLoggedIn() => accessToken != null;

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