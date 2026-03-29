import 'dart:convert';
import 'api_service.dart';

class OrderService {
  // Get all orders
  static Future<List<dynamic>> getOrders() async {
    final data = await ApiService.get("/orders/");
    return data as List;
  }

  // Place order (checkout)
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
}