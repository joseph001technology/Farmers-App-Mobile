class Order {
  final int id;
  final double totalPrice;
  final String createdAt;

  Order({
    required this.id,
    required this.totalPrice,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}