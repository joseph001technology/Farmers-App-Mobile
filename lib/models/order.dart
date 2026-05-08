class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;

  // Alias so both .price and .unitPrice work
  double get price => unitPrice;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      productId: json['product'] ?? json['product_id'] ?? 0,
      productName: json['product_name'] ?? json['name'] ?? 'Product',
      productImage: json['product_image'] ??
          json['image'] ??
          json['image_url'] ??
          json['imageUrl'],
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      unitPrice: double.tryParse(
              json['unit_price']?.toString() ??
                  json['price']?.toString() ??
                  '0') ??
          0.0,
    );
  }
}

class Order {
  final int id;
  final String status;
  final double totalPrice;
  final String createdAt;
  final String? paymentMethod;
  final String? deliveryAddress;
  final List<OrderItem>? items;

  // ── ADDED: farmer name from backend ─────────────────────────────
  final String? farmerName;

  // Convenience getters used by order_detail_screen
  List<OrderItem> get orderItems => items ?? [];
  bool get isDelivered => status == 'delivered';

  Order({
    required this.id,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.paymentMethod,
    this.deliveryAddress,
    this.items,
    this.farmerName, // ← ADDED
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // ── CHANGED: also accepts 'order_items' key from backend ────────
    final List<dynamic>? rawItems =
        json['order_items'] as List? ?? json['items'] as List?;

    return Order(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'pending',
      totalPrice:
          double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] ?? '',
      paymentMethod: json['payment_method'],
      deliveryAddress: json['delivery_address'],
      items: rawItems?.map((i) => OrderItem.fromJson(i)).toList(),
      // ── ADDED: reads 'farmer_name' or 'farmer' from backend ──────
      farmerName: json['farmer_name']?.toString() ??
          json['farmer']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'total_price': totalPrice,
      'created_at': createdAt,
      'payment_method': paymentMethod,
      'delivery_address': deliveryAddress,
    };
  }
}