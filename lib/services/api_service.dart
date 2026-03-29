import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "https://josephkiarie2.pythonanywhere.com/api";

  static Map<String, String> get headers {
    final token = AuthService.getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // GET
  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("GET $endpoint failed: ${response.statusCode}");
  }

  // POST
  static Future<http.Response> post(String endpoint, dynamic body) async {
    return await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // PUT
  static Future<http.Response> put(String endpoint, dynamic body) async {
    return await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // DELETE
  static Future<http.Response> delete(String endpoint) async {
    return await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );
  }
}