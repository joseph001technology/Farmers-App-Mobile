import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/dashboard.dart';

class DashboardService {
  static const String _baseUrl =
      'https://josephkiarie2.pythonanywhere.com/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.getToken()}',
      };

  /// Farmer's own sales dashboard
  static Future<FarmerDashboard> getFarmerDashboard() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/farmer/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return FarmerDashboard.fromJson(jsonDecode(response.body));
    }
    throw Exception(
        'Failed to load farmer dashboard: ${response.statusCode}');
  }

  /// Admin/county government platform-wide analytics
  static Future<AdminDashboard> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/admin/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return AdminDashboard.fromJson(jsonDecode(response.body));
    }
    throw Exception(
        'Failed to load admin dashboard: ${response.statusCode}');
  }
}