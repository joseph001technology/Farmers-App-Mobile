import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  // 🔥 Add to cart
  void addToCart(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItem(product: product);
    }
    notifyListeners();
  }

  // 🔥 Increase quantity
  void increaseQty(int productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity++;
      notifyListeners();
    }
  }

  // 🔥 Decrease quantity
  void decreaseQty(int productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity--;
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  // 🔥 Remove item
  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // 🔥 Total price
  double get totalPrice {
    double total = 0;
    _items.forEach((key, item) {
      total += item.product.price * item.quantity;
    });
    return total;
  }

  // 🔥 Total items count
  int get totalItems {
    int count = 0;
    _items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }

  // 🔥 Clear cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}