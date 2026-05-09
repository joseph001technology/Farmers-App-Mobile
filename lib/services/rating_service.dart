import 'dart:convert';
import '../helpers/api_helper.dart';
import '../models/rating.dart';

class RatingService {
  // ── GET /api/ratings/farmer/<farmer_id>/ ─────────────────────────
  static Future<FarmerRatingSummary> getFarmerRatingById(int farmerId) async {
    final res = await ApiHelper.get('/ratings/farmer/$farmerId/');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return FarmerRatingSummary.fromJson(data);
    }
    throw Exception('Failed to load farmer ratings (${res.statusCode})');
  }

  // ── GET /api/ratings/mine/ ────────────────────────────────────────
  static Future<List<Rating>> getMyRatings() async {
    final res = await ApiHelper.get('/ratings/mine/');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((r) => Rating.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load your ratings (${res.statusCode})');
  }

  // ── POST /api/ratings/ ────────────────────────────────────────────
  // NOTE: ApiHelper.post takes Map<String, dynamic> — NOT a JSON string
  static Future<void> submitRating({
    required int farmerId,
    required int orderId,
    required int stars,
    String? review,
  }) async {
    final body = <String, dynamic>{
      'farmer': farmerId,
      'order':  orderId,
      'stars':  stars,
      if (review != null && review.isNotEmpty) 'review': review,
    };

    final res = await ApiHelper.post('/ratings/', body);

    if (res.statusCode == 201) return;

    // Surface backend error message to the UI
    String msg = 'Failed to submit rating (${res.statusCode})';
    try {
      final err = jsonDecode(res.body);
      if (err is Map) {
        msg = err.values
            .map((v) => v is List ? v.join(', ') : v.toString())
            .join('\n');
      }
    } catch (_) {}
    throw Exception(msg);
  }
}