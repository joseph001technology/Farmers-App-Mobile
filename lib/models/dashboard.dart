// ── Farmer Dashboard ─────────────────────────────────────────────
class FarmerDashboard {
  final double totalRevenue;
  final int totalOrders;
  final int pendingOrders;
  final int deliveredOrders;
  final List<TopProduct>? topProducts;
  final List<RecentOrder>? recentOrders;

  FarmerDashboard({
    required this.totalRevenue,
    required this.totalOrders,
    required this.pendingOrders,
    required this.deliveredOrders,
    this.topProducts,
    this.recentOrders,
  });

  factory FarmerDashboard.fromJson(Map<String, dynamic> json) {
    return FarmerDashboard(
      totalRevenue:
          double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      topProducts: (json['top_products'] as List<dynamic>?)
          ?.map((p) => TopProduct.fromJson(p))
          .toList(),
      recentOrders: (json['recent_orders'] as List<dynamic>?)
          ?.map((o) => RecentOrder.fromJson(o))
          .toList(),
    );
  }
}

// ── Admin Dashboard ───────────────────────────────────────────────
class AdminDashboard {
  final double totalRevenue;
  final int totalOrders;
  final int pendingOrders;
  final int deliveredOrders;
  final int activeFarmers;
  final int totalConsumers;
  final int totalProducts;
  final List<TopProduct>? topProducts;
  final List<RecentOrder>? recentOrders;

  AdminDashboard({
    required this.totalRevenue,
    required this.totalOrders,
    required this.pendingOrders,
    required this.deliveredOrders,
    required this.activeFarmers,
    required this.totalConsumers,
    required this.totalProducts,
    this.topProducts,
    this.recentOrders,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      totalRevenue:
          double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      activeFarmers: json['active_farmers'] ?? 0,
      totalConsumers: json['total_consumers'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      topProducts: (json['top_products'] as List<dynamic>?)
          ?.map((p) => TopProduct.fromJson(p))
          .toList(),
      recentOrders: (json['recent_orders'] as List<dynamic>?)
          ?.map((o) => RecentOrder.fromJson(o))
          .toList(),
    );
  }
}

// ── Shared sub-models ─────────────────────────────────────────────
class TopProduct {
  final int productId;
  final String productName;
  final int totalOrders;
  final double totalRevenue;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.totalOrders,
    required this.totalRevenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['product_id'] ?? json['id'] ?? 0,
      productName: json['product_name'] ?? json['name'] ?? '—',
      totalOrders: json['total_orders'] ?? json['order_count'] ?? 0,
      totalRevenue:
          double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0,
    );
  }
}

class RecentOrder {
  final int orderId;
  final String? consumerName;
  final double totalPrice;
  final String status;
  final String createdAt;

  RecentOrder({
    required this.orderId,
    this.consumerName,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      orderId: json['id'] ?? json['order_id'] ?? 0,
      consumerName:
          json['consumer_name'] ?? json['consumer_username'],
      totalPrice:
          double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
    );
  }
}