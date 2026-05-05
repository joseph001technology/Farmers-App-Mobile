import 'dart:convert';
import '../helpers/api_helper.dart';
import '../models/dashboard.dart';

class DashboardService {
  // ── Farmer dashboard stats ───────────────────────────────────────
  static Future<FarmerDashboard> getFarmerDashboard() async {
    for (final path in [
      '/dashboard/farmer/', '/dashboard/', '/farmer/dashboard/',
    ]) {
      try {
        final r = await ApiHelper.get(path);
        if (r.statusCode == 200) {
          return FarmerDashboard.fromJson(jsonDecode(r.body));
        }
      } catch (_) {}
    }
    return FarmerDashboard(
        totalRevenue: 0, totalOrders: 0, pendingOrders: 0, deliveredOrders: 0);
  }

  // ── Admin dashboard stats ────────────────────────────────────────
  static Future<AdminDashboard> getAdminDashboard() async {
    for (final path in ['/dashboard/admin/', '/admin/dashboard/']) {
      try {
        final r = await ApiHelper.get(path);
        if (r.statusCode == 200) {
          return AdminDashboard.fromJson(jsonDecode(r.body));
        }
      } catch (_) {}
    }
    return AdminDashboard(
        totalRevenue: 0, totalOrders: 0, pendingOrders: 0,
        deliveredOrders: 0, activeFarmers: 0, totalConsumers: 0, totalProducts: 0);
  }

  // ── Farmer's own products ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyProducts() async {
    for (final path in [
      '/products/?mine=true', '/products/mine/', '/farmer/products/', '/products/',
    ]) {
      try {
        final r = await ApiHelper.get(path);
        if (r.statusCode == 200) {
          final body = jsonDecode(r.body);
          final List raw = body is Map
              ? (body['results'] ?? body['products'] ?? [])
              : body as List;
          return raw.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }
    return [];
  }

  // ── Update product stock ─────────────────────────────────────────
  // Backend field is `quantity` (not `stock`)
  static Future<bool> updateStock(int productId, int newQty) async {
    final body = {'quantity': newQty};

    // PATCH first, then PUT
    for (final path in ['/products/$productId/', '/products/$productId']) {
      try {
        final r = await ApiHelper.patch(path, body);
        if (r.statusCode == 200 || r.statusCode == 204) return true;
      } catch (_) {}
    }
    for (final path in ['/products/$productId/', '/products/$productId']) {
      try {
        final r = await ApiHelper.put(path, body);
        if (r.statusCode == 200 || r.statusCode == 204) return true;
      } catch (_) {}
    }
    return false;
  }

  // ── Add new product ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> addProduct(
      Map<String, dynamic> data) async {
    final r = await ApiHelper.post('/products/', data);
    if (r.statusCode == 200 || r.statusCode == 201) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(r.body);
  }

  // ── Farmer orders ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getFarmerOrders() async {
    for (final path in [
      '/orders/?farmer=me', '/farmer/orders/', '/orders/',
    ]) {
      try {
        final r = await ApiHelper.get(path);
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