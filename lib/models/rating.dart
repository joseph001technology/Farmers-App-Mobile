class Rating {
  final int id;
  final int farmer;
  final String farmerName;
  final int consumer;
  final String consumerName;
  final int order;
  final int stars;
  final String? review;
  final String createdAt;

  // UI aliases so existing widgets don't break
  int get rating => stars;
  String? get comment => review;
  String? get productName => null; // backend doesn't have per-product ratings

  const Rating({
    required this.id,
    required this.farmer,
    required this.farmerName,
    required this.consumer,
    required this.consumerName,
    required this.order,
    required this.stars,
    this.review,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> j) {
    return Rating(
      id:           (j['id']       as num).toInt(),
      farmer:       (j['farmer']   as num).toInt(),
      farmerName:   j['farmer_name']?.toString()   ?? 'Farmer',
      consumer:     (j['consumer'] as num).toInt(),
      consumerName: j['consumer_name']?.toString() ?? 'Consumer',
      order:        (j['order']    as num).toInt(),
      stars:        (j['stars']    as num).toInt(),
      review:       j['review']?.toString(),
      createdAt:    j['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id':            id,
    'farmer':        farmer,
    'farmer_name':   farmerName,
    'consumer':      consumer,
    'consumer_name': consumerName,
    'order':         order,
    'stars':         stars,
    'review':        review,
    'created_at':    createdAt,
  };
}

class FarmerRatingSummary {
  final int farmerId;
  final String farmerName;
  final double averageRating;
  final int totalRatings;
  final List<Rating> ratings;

  const FarmerRatingSummary({
    required this.farmerId,
    required this.farmerName,
    required this.averageRating,
    required this.totalRatings,
    required this.ratings,
  });

  factory FarmerRatingSummary.fromJson(Map<String, dynamic> j) {
    final rawRatings = j['ratings'] as List? ?? [];
    return FarmerRatingSummary(
      farmerId:      (j['farmer_id']    as num).toInt(),
      farmerName:    j['farmer_name']?.toString() ?? 'Farmer',
      averageRating: (j['average_stars'] as num?)?.toDouble() ?? 0.0,
      totalRatings:  (j['total_ratings'] as num?)?.toInt() ?? 0,
      ratings:       rawRatings
          .map((r) => Rating.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}