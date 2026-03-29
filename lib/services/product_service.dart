import 'dart:convert';
import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  // Fetch all products
  static Future<List<Product>> getProducts() async {
    final data = await ApiService.get("/products/");
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  // Fetch single product
  static Future<Product> getProduct(int id) async {
    final data = await ApiService.get("/products/$id/");
    return Product.fromJson(data);
  }
}