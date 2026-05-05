class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final String? imageUrl;
  final String? unit;
  final String? category;      // backend slug: 'animal_products', 'vegetables' …
  final String? harvestDate;
  final String? farmerName;
  final int? farmerId;
  final String? farmerPhone;
  final String? farmerLocation;
  final int? stock;            // maps to backend field `quantity`
  final double? averageRating;
  final int? ratingCount;

  // Human-readable category label
  String get categoryLabel {
    switch (category?.toLowerCase()) {
      case 'vegetables':        return 'Vegetables';
      case 'fruits':            return 'Fruits';
      case 'grains':            return 'Grains';
      case 'animal_products':   return 'Animal Products';
      case 'manure':            return 'Manure';
      case 'others':            return 'Others';
      default:                  return category ?? '';
    }
  }

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl,
    this.unit,
    this.category,
    this.harvestDate,
    this.farmerName,
    this.farmerId,
    this.farmerPhone,
    this.farmerLocation,
    this.stock,
    this.averageRating,
    this.ratingCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // ── Farmer field ────────────────────────────────────────────────
    // Backend serialiser returns: "jose (254742906228)"
    int? farmerId;
    String? farmerName;
    String? farmerPhone;

    final rawFarmer = json['farmer'];
    if (rawFarmer is int) {
      farmerId = rawFarmer;
    } else if (rawFarmer is Map) {
      farmerId   = rawFarmer['id'];
      farmerName = rawFarmer['username'] ?? rawFarmer['name'];
      farmerPhone = rawFarmer['phone'] ?? rawFarmer['phone_number'];
    } else if (rawFarmer is String) {
      final asInt = int.tryParse(rawFarmer);
      if (asInt != null) {
        farmerId = asInt;
      } else {
        // "name (phone)" pattern
        final m = RegExp(r'^(.*?)\s*\((\d+)\)\s*$').firstMatch(rawFarmer);
        if (m != null) {
          farmerName  = m.group(1)?.trim();
          farmerPhone = m.group(2);
        } else {
          farmerName = rawFarmer.trim();
        }
      }
    }

    // Explicit farmer_name / farmer_username fields take priority
    final explName = json['farmer_name'] ?? json['farmer_username'];
    if (explName != null && explName.toString().isNotEmpty) {
      farmerName = explName.toString();
    }
    final explPhone = json['farmer_phone'];
    if (explPhone != null && explPhone.toString().isNotEmpty) {
      farmerPhone = explPhone.toString();
    }

    // ── Stock: backend calls it `quantity` ───────────────────────────
    int? stock;
    final rawStock = json['quantity'] ?? json['stock'];
    if (rawStock is int) {
      stock = rawStock;
    } else if (rawStock != null) {
      stock = int.tryParse(rawStock.toString());
    }

    // ── Ratings ──────────────────────────────────────────────────────
    double? avgRating;
    final rawAvg = json['average_rating'];
    if (rawAvg != null) avgRating = double.tryParse(rawAvg.toString());

    int? ratingCount;
    final rawCount = json['rating_count'];
    if (rawCount is int) {
      ratingCount = rawCount;
    } else if (rawCount != null) {
      ratingCount = int.tryParse(rawCount.toString());
    }

    // ── Category: store raw slug from backend ────────────────────────
    final rawCategory = json['category']?.toString();

    return Product(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
      imageUrl: json['image'] ?? json['image_url'] ?? json['imageUrl'],
      unit: json['unit']?.toString(),
      category: rawCategory,
      harvestDate: json['harvest_date']?.toString(),
      farmerName: farmerName,
      farmerId: farmerId,
      farmerPhone: farmerPhone,
      farmerLocation: json['farmer_location']?.toString(),
      stock: stock,
      averageRating: avgRating,
      ratingCount: ratingCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'description': description,
    'image': imageUrl,
    'unit': unit,
    'category': category,
    'harvest_date': harvestDate,
    'farmer_name': farmerName,
    'farmer_id': farmerId,
    'farmer_phone': farmerPhone,
    'farmer_location': farmerLocation,
    'quantity': stock,
    'average_rating': averageRating,
    'rating_count': ratingCount,
  };
}