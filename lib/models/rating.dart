// lib/models/rating.dart
class Rating {
  final int id;
  final int farmerId;
  final String farmerName;
  final int consumerId;
  final String consumerName;
  final int orderId;
  final int stars;
  final String? review;
  final String createdAt;

  Rating({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.consumerId,
    required this.consumerName,
    required this.orderId,
    required this.stars,
    this.review,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      farmerId: json['farmer'],
      farmerName: json['farmer_name'] ?? '',
      consumerId: json['consumer'],
      consumerName: json['consumer_name'] ?? '',
      orderId: json['order'],
      stars: json['stars'],
      review: json['review'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class FarmerRatingSummary {
  final int farmerId;
  final String farmerName;
  final double averageStars;
  final int totalRatings;
  final List<Rating> ratings;

  FarmerRatingSummary({
    required this.farmerId,
    required this.farmerName,
    required this.averageStars,
    required this.totalRatings,
    required this.ratings,
  });

  factory FarmerRatingSummary.fromJson(Map<String, dynamic> json) {
    final ratingsJson = json['ratings'] as List<dynamic>? ?? [];
    return FarmerRatingSummary(
      farmerId: json['farmer_id'],
      farmerName: json['farmer_name'] ?? '',
      averageStars: double.tryParse(
              json['average_stars'].toString()) ?? 0.0,
      totalRatings: json['total_ratings'],
      ratings: ratingsJson
          .map((e) => Rating.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}