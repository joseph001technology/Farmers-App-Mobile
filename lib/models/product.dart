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
    this.stock,
    this.averageRating,
    this.ratingCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      description: json['description'] ?? '',
      imageUrl: json['image'] ?? json['image_url'] ?? json['imageUrl'],
      unit: json['unit'],
      category: json['category'],
      harvestDate: json['harvest_date'],
      farmerName: json['farmer_name'] ?? json['farmer_username'],
      stock: json['stock'] != null
          ? int.tryParse(json['stock'].toString())
          : null,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      ratingCount: json['rating_count'] != null
          ? int.tryParse(json['rating_count'].toString())
          : null,
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
      'stock': stock,
      'average_rating': averageRating,
      'rating_count': ratingCount,
    };
  }
}