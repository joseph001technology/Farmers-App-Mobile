class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final String? imageUrl;
  final String? unit;
  final String? category;
  final String? harvestDate;
  final String? farmerName;
  final int? farmerId;
  final String? farmerPhone;
  final String? farmerLocation;
  final int? stock;
  final double? averageRating;
  final int? ratingCount;

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
    // ── Safely parse farmer field ─────────────────────────────────
    // Backend may return farmer as:
    //   • an int  →  42
    //   • a string that is purely numeric  →  "42"
    //   • a string like "jose (254742906228)"
    //   • a map  →  { "id": 1, "username": "jose", "phone": "..." }
    //   • null
    int? farmerId;
    String? farmerName;
    String? farmerPhone;

    final rawFarmer = json['farmer'];

    if (rawFarmer is int) {
      farmerId = rawFarmer;
    } else if (rawFarmer is Map) {
      // Nested farmer object
      farmerId = rawFarmer['id'];
      farmerName = rawFarmer['username'] ??
          rawFarmer['name'] ??
          rawFarmer['farmer_name'];
      farmerPhone = rawFarmer['phone'] ?? rawFarmer['phone_number'];
    } else if (rawFarmer is String) {
      // Try to parse as a plain integer string first
      final asInt = int.tryParse(rawFarmer);
      if (asInt != null) {
        farmerId = asInt;
      } else {
        // Format: "name (phone)" e.g. "jose (254742906228)"
        final parenMatch =
            RegExp(r'^(.*?)\s*\((\d+)\)\s*$').firstMatch(rawFarmer);
        if (parenMatch != null) {
          farmerName = parenMatch.group(1)?.trim();
          farmerPhone = parenMatch.group(2);
        } else {
          // Just treat the whole string as the farmer name
          farmerName = rawFarmer.trim();
        }
      }
    }

    // Prefer explicit farmer_name / farmer_username fields if present
    final explicitFarmerName =
        json['farmer_name'] ?? json['farmer_username'];
    if (explicitFarmerName != null &&
        explicitFarmerName.toString().isNotEmpty) {
      farmerName = explicitFarmerName.toString();
    }

    final explicitFarmerPhone = json['farmer_phone'];
    if (explicitFarmerPhone != null &&
        explicitFarmerPhone.toString().isNotEmpty) {
      farmerPhone = explicitFarmerPhone.toString();
    }

    // ── Safely parse stock ────────────────────────────────────────
    // stock could be an int, a string, or null
    int? stock;
    final rawStock = json['stock'];
    if (rawStock is int) {
      stock = rawStock;
    } else if (rawStock != null) {
      stock = int.tryParse(rawStock.toString());
    }

    // ── Safely parse ratings ──────────────────────────────────────
    double? averageRating;
    final rawAvg = json['average_rating'];
    if (rawAvg != null) {
      averageRating = double.tryParse(rawAvg.toString());
    }

    int? ratingCount;
    final rawCount = json['rating_count'];
    if (rawCount is int) {
      ratingCount = rawCount;
    } else if (rawCount != null) {
      ratingCount = int.tryParse(rawCount.toString());
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
      imageUrl: json['image'] ?? json['image_url'] ?? json['imageUrl'],
      unit: json['unit']?.toString(),
      category: json['category']?.toString(),
      harvestDate: json['harvest_date']?.toString(),
      farmerName: farmerName,
      farmerId: farmerId,
      farmerPhone: farmerPhone,
      farmerLocation: json['farmer_location']?.toString(),
      stock: stock,
      averageRating: averageRating,
      ratingCount: ratingCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'stock': stock,
      'average_rating': averageRating,
      'rating_count': ratingCount,
    };
  }
}