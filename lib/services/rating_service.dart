import 'dart:convert';
import '../helpers/api_helper.dart';
import '../models/rating.dart';

class RatingService {
  // ── Fetch ratings for a product ──────────────────────────────────
  static Future<List<Rating>> getProductRatings(int productId) async {
    for (final path in [
      '/ratings/?product=$productId',
      '/products/$productId/ratings/',
      '/ratings/product/$productId/',
    ]) {
      try {
        final r = await ApiHelper.get(path);
        if (r.statusCode == 200) {
          final body = jsonDecode(r.body);
          final List raw = body is Map
              ? (body['results'] ?? body['ratings'] ?? [])
              : body as List;
          return raw.map((j) => Rating.fromJson(j)).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  // ── Fetch farmer rating summary ──────────────────────────────────
  static Future<FarmerRatingSummary> getFarmerRatings({int? farmerId}) async {
    final paths = farmerId != null
        ? ['/ratings/farmer/$farmerId/', '/ratings/?farmer=$farmerId']
        : ['/ratings/my-ratings/', '/ratings/mine/', '/ratings/?mine=true'];

    for (final path in paths) {
      try {
        final r = await ApiHelper.get(path);
        if (r.statusCode == 200) {
          final body = jsonDecode(r.body);
          if (body is List) {
            final ratings = body.map((j) => Rating.fromJson(j)).toList();
            final total = ratings.fold<double>(0, (s, r) => s + r.rating);
            return FarmerRatingSummary(
              averageRating: ratings.isEmpty ? 0 : total / ratings.length,
              totalRatings: ratings.length,
              ratings: ratings,
            );
          }
          if (body is Map) {
            if (body['ratings'] != null) {
              return FarmerRatingSummary.fromJson(body as Map<String, dynamic>);
            }
            if (body['results'] != null) {
              final ratings = (body['results'] as List)
                  .map((j) => Rating.fromJson(j)).toList();
              final total = ratings.fold<double>(0, (s, r) => s + r.rating);
              return FarmerRatingSummary(
                averageRating: ratings.isEmpty ? 0 : total / ratings.length,
                totalRatings: ratings.length,
                ratings: ratings,
              );
            }
          }
        }
      } catch (_) {}
    }
    return FarmerRatingSummary(averageRating: 0, totalRatings: 0, ratings: []);
  }

  // ── Submit a rating ──────────────────────────────────────────────
  // Backend model uses `stars` field (from the serialiser shown in code)
  static Future<void> submitRating({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    final body = {
      'product': productId,
      'stars': rating,       // backend field name
      'rating': rating,      // fallback
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      if (comment != null && comment.isNotEmpty) 'review': comment,
    };

    for (final path in [
      '/ratings/', '/ratings', '/products/$productId/ratings/', '/reviews/',
    ]) {
      try {
        final r = await ApiHelper.post(path, body);
        if (r.statusCode == 200 || r.statusCode == 201 || r.statusCode == 202) {
          return;
        }
        if (r.statusCode == 400) {
          final err = jsonDecode(r.body);
          final msg = err is Map
              ? (err.values.first is List
                  ? (err.values.first as List).first.toString()
                  : err.values.first.toString())
              : r.body;
          throw Exception(msg);
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
    }
    throw Exception('Could not submit review. Check your connection.');
  }
}