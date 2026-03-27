import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Add product
  void addToCart(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }

    notifyListeners();
  }

  // Remove product
  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // Increase quantity
  void increaseQty(String productId) {
    final item = _items.firstWhere((item) => item.product.id == productId);
    item.quantity++;
    notifyListeners();
  }

  // Decrease quantity
  void decreaseQty(String productId) {
    final item = _items.firstWhere((item) => item.product.id == productId);

    if (item.quantity > 1) {
      item.quantity--;
    } else {
      removeFromCart(productId);
    }

    notifyListeners();
  }

  // Total price
  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  bool get isEmpty => _items.isEmpty;
}
