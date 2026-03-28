class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;   // ✅ match UI
  final String? unit;       // ✅ add unit back
  final String? farmer;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.unit,
    this.farmer,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,

      // ✅ handle both possible backend names
      imageUrl: json['image'] ?? json['imageUrl'],

      // ✅ fallback if backend doesn't have unit
      unit: json['unit'] ?? '',

      farmer: json['farmer']?.toString(),
    );
  }
}