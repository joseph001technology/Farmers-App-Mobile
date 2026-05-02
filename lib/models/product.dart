 
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String? unit;
  final String? farmer;
  final String? category;
  final String? harvestDate;
  final double? averageRating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.unit,
    this.farmer,
    this.category,
    this.harvestDate,
    this.averageRating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image'] ?? json['imageUrl'],
      unit: json['unit'] ?? '',
      farmer: json['farmer']?.toString(),
      category: json['category'],
      harvestDate: json['harvest_date'],
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
    );
  }
}