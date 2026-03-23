class Product {
  final String id;
  final String name;
  final double price;
  final String unit;        // e.g. "per kg", "per bunch", "per piece"
  final String description;
  final String imageUrl;    // we'll use network URLs for now (real photos later)

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.description,
    required this.imageUrl,
  });
}