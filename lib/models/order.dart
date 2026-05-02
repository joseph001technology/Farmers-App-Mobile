 
class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product'],
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      quantity: json['quantity'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}

class Order {
  final int id;
  final double totalPrice;
  final String createdAt;
  final String status;
  final String paymentMethod;
  final String? deliveryAddress;
  final List<OrderItem> orderItems;

  Order({
    required this.id,
    required this.totalPrice,
    required this.createdAt,
    required this.status,
    this.paymentMethod = 'mpesa',
    this.deliveryAddress,
    this.orderItems = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['order_items'] as List<dynamic>? ?? [];
    return Order(
      id: json['id'],
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'mpesa',
      deliveryAddress: json['delivery_address'],
      orderItems: itemsJson
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isPod => paymentMethod == 'pod';
  bool get isPending =>
      status == 'pending' || status == 'pending_delivery';
  bool get isPaid => status == 'paid';
  bool get isDelivered => status == 'delivered';
  bool get isOutForDelivery => status == 'out_for_delivery';
}