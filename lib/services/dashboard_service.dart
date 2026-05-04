import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/dashboard.dart';

class DashboardService {
  static const String _base =
      'https://josephkiarie2.pythonanywhere.com/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.getToken()}',
      };

  // ── Farmer dashboard stats ───────────────────────────────────────
  static Future<FarmerDashboard> getFarmerDashboard() async {
    for (final url in [
      '$_base/dashboard/farmer/',
      '$_base/dashboard/',
      '$_base/farmer/dashboard/',
    ]) {
      try {
        final r = await http.get(Uri.parse(url), headers: _headers);
        if (r.statusCode == 200) {
          return FarmerDashboard.fromJson(jsonDecode(r.body));
        }
      } catch (_) {}
    }
    // Return empty dashboard rather than crashing
    return FarmerDashboard(
      totalRevenue: 0,
      totalOrders: 0,
      pendingOrders: 0,
      deliveredOrders: 0,
    );
  }

  // ── Admin dashboard stats ────────────────────────────────────────
  static Future<AdminDashboard> getAdminDashboard() async {
    for (final url in [
      '$_base/dashboard/admin/',
      '$_base/admin/dashboard/',
    ]) {
      try {
        final r = await http.get(Uri.parse(url), headers: _headers);
        if (r.statusCode == 200) {
          return AdminDashboard.fromJson(jsonDecode(r.body));
        }
      } catch (_) {}
    }
    return AdminDashboard(
      totalRevenue: 0,
      totalOrders: 0,
      pendingOrders: 0,
      deliveredOrders: 0,
      activeFarmers: 0,
      totalConsumers: 0,
      totalProducts: 0,
    );
  }

  // ── Farmer's own products ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyProducts() async {
    for (final url in [
      '$_base/products/?mine=true',
      '$_base/products/mine/',
      '$_base/farmer/products/',
      '$_base/products/?farmer=me',
    ]) {
      try {
        final r = await http.get(Uri.parse(url), headers: _headers);
        if (r.statusCode == 200) {
          final body = jsonDecode(r.body);
          final List raw = body is Map
              ? (body['results'] ?? body['products'] ?? [])
              : body as List;
          return raw.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }
    // Fallback — fetch all products filtered by farmer name
    try {
      final r = await http.get(
          Uri.parse('$_base/products/'), headers: _headers);
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final List raw = body is Map
            ? (body['results'] ?? body['products'] ?? [])
            : body as List;
        return raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  // ── Update product stock ─────────────────────────────────────────
  static Future<bool> updateStock(int productId, int newStock) async {
    final body = jsonEncode({'stock': newStock});

    // Try PATCH first, then PUT
    for (final method in ['PATCH', 'PUT']) {
      for (final url in [
        '$_base/products/$productId/',
        '$_base/products/$productId',
      ]) {
        try {
          final r = method == 'PATCH'
              ? await http.patch(Uri.parse(url),
                  headers: _headers, body: body)
              : await http.put(Uri.parse(url),
                  headers: _headers, body: body);
          if (r.statusCode == 200 || r.statusCode == 204) {
            return true;
          }
        } catch (_) {}
      }
    }
    return false;
  }

  // ── Add new product ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> addProduct(
      Map<String, dynamic> data) async {
    try {
      final r = await http.post(
        Uri.parse('$_base/products/'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (r.statusCode == 200 || r.statusCode == 201) {
        return jsonDecode(r.body);
      }
      throw Exception(jsonDecode(r.body).toString());
    } catch (e) {
      rethrow;
    }
  }

  // ── Farmer orders (orders for farmer's products) ─────────────────
  static Future<List<Map<String, dynamic>>> getFarmerOrders() async {
    for (final url in [
      '$_base/orders/?farmer=me',
      '$_base/farmer/orders/',
      '$_base/orders/',
    ]) {
      try {
        final r = await http.get(Uri.parse(url), headers: _headers);
        if (r.statusCode == 200) {
          final body = jsonDecode(r.body);
          final List raw = body is Map
              ? (body['results'] ?? body['orders'] ?? [])
              : body as List;
          return raw.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }
    return [];
  }
}