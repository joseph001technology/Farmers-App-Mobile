// lib/services/rating_service.dart
import 'dart:convert';
import '../models/rating.dart';
import 'api_service.dart';

class RatingService {
  /// Submit a rating for a farmer after order is delivered
  static Future<Rating> createRating({
    required int farmerId,
    required int orderId,
    required int stars,
    String? review,
  }) async {
    final response = await ApiService.post('/ratings/', {
      'farmer': farmerId,
      'order': orderId,
      'stars': stars,
      if (review != null && review.isNotEmpty) 'review': review,
    });
    if (response.statusCode == 201) {
      return Rating.fromJson(jsonDecode(response.body));
    }
    throw Exception(
        'Failed to submit rating: ${response.statusCode} ${response.body}');
  }

  /// Get all ratings for a specific farmer
  static Future<FarmerRatingSummary> getFarmerRatings(int farmerId) async {
    final data = await ApiService.get('/ratings/farmer/$farmerId/');
    return FarmerRatingSummary.fromJson(data);
  }

  /// Get ratings submitted by the current user
  static Future<List<Rating>> getMyRatings() async {
    final data = await ApiService.get('/ratings/mine/');
    return (data as List)
        .map((e) => Rating.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}