import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Future<Map<String, String>> _authHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access");
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    var headers = await _authHeaders();
    var response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    // Handle 401 → Refresh
    if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _authHeaders();
        response = await http.post(
          Uri.parse('$baseUrl/$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        );
      } else {
        // Force login
        throw Exception("Session expired. Login again.");
      }
    }
    return response;
  }

  Future<http.Response> get(String endpoint) async {
    var headers = await _authHeaders();
    var response = await http.get(Uri.parse('$baseUrl/$endpoint'), headers: headers);

    if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _authHeaders();
        response = await http.get(Uri.parse('$baseUrl/$endpoint'), headers: headers);
      } else {
        throw Exception("Session expired. Login again.");
      }
    }
    return response;
  }

  Future<bool> _refreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? refresh = prefs.getString("refresh");
    if (refresh == null) return false;

    var res = await http.post(
      Uri.parse('$baseUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (res.statusCode == 200) {
      var data = jsonDecode(res.body);
      prefs.setString("access", data['access']);
      return true;
    }
    return false;
  }
}