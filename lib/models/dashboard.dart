 
class TopProduct {
  final String name;
  final int quantitySold;
  final double revenue;

  TopProduct({
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      name: json['name'] ?? '',
      quantitySold: json['quantity_sold'] ?? 0,
      revenue: double.tryParse(json['revenue'].toString()) ?? 0.0,
    );
  }
}

class DailyRevenue {
  final String date;
  final double revenue;
  final int orders;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: json['date'] ?? '',
      revenue: double.tryParse(json['revenue'].toString()) ?? 0.0,
      orders: json['orders'] ?? 0,
    );
  }
}

class FarmerDashboard {
  final int totalOrders;
  final double totalRevenue;
  final int paidOrders;
  final int pendingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int totalProductsListed;
  final double averageRating;
  final int totalRatings;
  final List<TopProduct> topProducts;
  final List<DailyRevenue> revenueLast7Days;

  FarmerDashboard({
    required this.totalOrders,
    required this.totalRevenue,
    required this.paidOrders,
    required this.pendingOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalProductsListed,
    required this.averageRating,
    required this.totalRatings,
    required this.topProducts,
    required this.revenueLast7Days,
  });

  factory FarmerDashboard.fromJson(Map<String, dynamic> json) {
    final topJson = json['top_products'] as List<dynamic>? ?? [];
    final revenueJson = json['revenue_last_7_days'] as List<dynamic>? ?? [];
    return FarmerDashboard(
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue:
          double.tryParse(json['total_revenue'].toString()) ?? 0.0,
      paidOrders: json['paid_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      totalProductsListed: json['total_products_listed'] ?? 0,
      averageRating:
          double.tryParse(json['average_rating'].toString()) ?? 0.0,
      totalRatings: json['total_ratings'] ?? 0,
      topProducts:
          topJson.map((e) => TopProduct.fromJson(e)).toList(),
      revenueLast7Days:
          revenueJson.map((e) => DailyRevenue.fromJson(e)).toList(),
    );
  }
}

class TopFarmer {
  final String farmer;
  final double revenue;
  final int orders;

  TopFarmer({
    required this.farmer,
    required this.revenue,
    required this.orders,
  });

  factory TopFarmer.fromJson(Map<String, dynamic> json) {
    return TopFarmer(
      farmer: json['farmer'] ?? '',
      revenue: double.tryParse(json['revenue'].toString()) ?? 0.0,
      orders: json['orders'] ?? 0,
    );
  }
}

class CategoryStat {
  final String category;
  final int count;

  CategoryStat({required this.category, required this.count});

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class AdminDashboard {
  final int totalUsers;
  final int totalFarmers;
  final int totalConsumers;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final Map<String, dynamic> ordersByStatus;
  final List<TopProduct> topSellingProducts;
  final List<TopFarmer> topFarmersByRevenue;
  final List<CategoryStat> productsByCategory;
  final List<DailyRevenue> ordersLast7Days;

  AdminDashboard({
    required this.totalUsers,
    required this.totalFarmers,
    required this.totalConsumers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.ordersByStatus,
    required this.topSellingProducts,
    required this.topFarmersByRevenue,
    required this.productsByCategory,
    required this.ordersLast7Days,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    final topJson = json['top_selling_products'] as List<dynamic>? ?? [];
    final farmersJson =
        json['top_farmers_by_revenue'] as List<dynamic>? ?? [];
    final catJson = json['products_by_category'] as List<dynamic>? ?? [];
    final dailyJson = json['orders_last_7_days'] as List<dynamic>? ?? [];
    return AdminDashboard(
      totalUsers: json['total_users'] ?? 0,
      totalFarmers: json['total_farmers'] ?? 0,
      totalConsumers: json['total_consumers'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue:
          double.tryParse(json['total_revenue'].toString()) ?? 0.0,
      ordersByStatus:
          Map<String, dynamic>.from(json['orders_by_status'] ?? {}),
      topSellingProducts:
          topJson.map((e) => TopProduct.fromJson(e)).toList(),
      topFarmersByRevenue:
          farmersJson.map((e) => TopFarmer.fromJson(e)).toList(),
      productsByCategory:
          catJson.map((e) => CategoryStat.fromJson(e)).toList(),
      ordersLast7Days:
          dailyJson.map((e) => DailyRevenue.fromJson(e)).toList(),
    );
  }
}