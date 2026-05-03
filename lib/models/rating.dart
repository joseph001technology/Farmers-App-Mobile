class Rating {
  final int id;
  final int productId;
  final String? productName;
  final int consumerId;
  final String? consumerName;
  final int rating; // 1–5
  final String? comment;
  final String createdAt;

  Rating({
    required this.id,
    required this.productId,
    this.productName,
    required this.consumerId,
    this.consumerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] ?? 0,
      productId: json['product'] ?? json['product_id'] ?? 0,
      productName: json['product_name'],
      consumerId: json['consumer'] ?? json['consumer_id'] ?? 0,
      consumerName: json['consumer_name'] ?? json['consumer_username'],
      rating: int.tryParse(json['rating'].toString()) ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': productId,
      'consumer': consumerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
    };
  }
}

/// Summary object returned when viewing farmer-level ratings
class FarmerRatingSummary {
  final double averageRating;
  final int totalRatings;
  final List<Rating> ratings;

  FarmerRatingSummary({
    required this.averageRating,
    required this.totalRatings,
    required this.ratings,
  });

  factory FarmerRatingSummary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawRatings = json['ratings'] ?? [];
    return FarmerRatingSummary(
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0,
      totalRatings: json['total_ratings'] ?? rawRatings.length,
      ratings: rawRatings.map((r) => Rating.fromJson(r)).toList(),
    );
  }
}