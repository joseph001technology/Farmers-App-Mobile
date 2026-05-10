class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;

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
      productImage: json['product_image'] ?? json['image'] ?? json['image_url'],
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
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
  // Added Farmer Info
  final String? farmerName;
  final String? farmerImage;

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
    this.farmerName,
    this.farmerImage,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawItems = json['order_items'] as List? ?? json['items'] as List?;
    
    // Handles nested farmer object or flat farmer_name field
    String? fName = json['farmer_name']?.toString();
    String? fImg = json['farmer_image']?.toString();
    if (json['farmer'] is Map) {
      fName = json['farmer']['name'];
      fImg = json['farmer']['profile_image'];
    } else if (json['farmer'] != null) {
      fName = json['farmer'].toString();
    }

    return Order(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'pending',
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] ?? '',
      paymentMethod: json['payment_method'],
      deliveryAddress: json['delivery_address'],
      items: rawItems?.map((i) => OrderItem.fromJson(i)).toList(),
      farmerName: fName,
      farmerImage: fImg,
    );
  }
}