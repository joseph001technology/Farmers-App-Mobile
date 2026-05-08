import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  // Fetch all products
  static Future<List<Product>> getProducts() async {
    final data = await ApiService.get("/products/");
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  // ── ADDED: alias used by home_screen.dart ────────────────────────
  static Future<List<Product>> fetchProducts() => getProducts();

  // Fetch single product
  static Future<Product> getProduct(int id) async {
    final data = await ApiService.get("/products/$id/");
    return Product.fromJson(data);
  }
}