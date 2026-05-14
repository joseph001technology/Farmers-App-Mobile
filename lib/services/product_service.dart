import 'dart:convert';
import '../models/product.dart';
import '../helpers/api_helper.dart';

class ProductService {
  /// Fetch all products — works with or without auth token.
  static Future<List<Product>> getProducts() async {
    final res = await ApiHelper.get('/products/');

    if (res.statusCode == 200) {
      final List raw = jsonDecode(res.body) as List;
      return raw
          .cast<Map<String, dynamic>>()
          .map((e) => Product.fromJson(e))
          .toList();
    }

    // Surface a useful error instead of swallowing it
    throw Exception(
        'Failed to load products (${res.statusCode}): ${res.body}');
  }

  /// Alias kept for backwards compatibility
  static Future<List<Product>> fetchProducts() => getProducts();

  /// Fetch a single product by ID
  static Future<Product> getProduct(int id) async {
    final res = await ApiHelper.get('/products/$id/');

    if (res.statusCode == 200) {
      return Product.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }

    throw Exception(
        'Failed to load product $id (${res.statusCode})');
  }
}