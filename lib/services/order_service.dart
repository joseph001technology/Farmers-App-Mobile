import 'dart:convert';
import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  // ── Get all orders — original ─────────────────────────────────────
  static Future<List<dynamic>> getOrders() async {
    final data = await ApiService.get("/orders/");
    return data as List;
  }

  // ── Place order (checkout) — original signature kept ──────────────
  static Future<Map<String, dynamic>> checkout({
    required List<Map<String, dynamic>> items,
    required String phoneNumber,
  }) async {
    final response = await ApiService.post("/orders/checkout/", {
      "items": items,
      "phone_number": phoneNumber,
    });
    return jsonDecode(response.body);
  }

  // ── NEW: Get single order detail ──────────────────────────────────
  static Future<Order> getOrderDetail(int orderId) async {
    final data = await ApiService.get("/orders/$orderId/");
    return Order.fromJson(data as Map<String, dynamic>);
  }

  // ── NEW: Cancel order ─────────────────────────────────────────────
  static Future<bool> cancelOrder(int orderId) async {
    try {
      final response =
          await ApiService.post("/orders/$orderId/cancel/", {});
      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ── NEW: Fetch receipt ────────────────────────────────────────────
  /// Returns the full order receipt for paid/delivered orders.
  /// Throws an Exception if the order status is not paid/delivered.
  static Future<Order> getReceipt(int orderId) async {
    final data = await ApiService.get("/orders/$orderId/receipt/");
    return Order.fromJson(data as Map<String, dynamic>);
  }
}