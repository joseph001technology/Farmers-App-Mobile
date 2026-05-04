import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/rating.dart';

class RatingService {
  static const String _base =
      'https://josephkiarie2.pythonanywhere.com/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.getToken()}',
      };

  // ── GET product ratings ──────────────────────────────────────────
  static Future<List<Rating>> getProductRatings(int productId) async {
    // Try both common URL patterns
    for (final url in [
      '$_base/ratings/?product=$productId',
      '$_base/products/$productId/ratings/',
      '$_base/ratings/product/$productId/',
    ]) {
      try {
        final r = await http.get(Uri.parse(url), headers: _headers);
        if (r.statusCode == 200) {
          final body = jsonDecode(r.body);
          // Handle paginated response { results: [...] } or plain list
          final List raw = body is Map
              ? (body['results'] ?? body['ratings'] ?? [])
              : body as List;
          return raw.map((j) => Rating.fromJson(j)).toList();
        }
      } catch (_) {}
    }
    return []; // return empty rather than throwing — ratings are optional
  }

  // ── GET farmer ratings summary ───────────────────────────────────
  static Future<FarmerRatingSummary> getFarmerRatings(
      {int? farmerId}) async {
    final urls = farmerId != null
        ? [
            '$_base/ratings/farmer/$farmerId/',
            '$_base/ratings/?farmer=$farmerId',
          ]
        : [
            '$_base/ratings/my-ratings/',
            '$_base/ratings/mine/',
            '$_base/ratings/?mine=true',
          ];

    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: _headers);
        if (r.statusCode == 200) {
          final body = jsonDecode(r.body);
          if (body is List) {
            final ratings = body.map((j) => Rating.fromJson(j)).toList();
            final total =
                ratings.fold<double>(0, (s, r) => s + r.rating);
            return FarmerRatingSummary(
              averageRating:
                  ratings.isEmpty ? 0 : total / ratings.length,
              totalRatings: ratings.length,
              ratings: ratings,
            );
          }
          if (body is Map) {
            // Check if it has a ratings list inside
            if (body['ratings'] != null) {
              return FarmerRatingSummary.fromJson(body as Map<String, dynamic>);
            }
            // Might be paginated { results: [...] }
            if (body['results'] != null) {
              final ratings = (body['results'] as List)
                  .map((j) => Rating.fromJson(j))
                  .toList();
              final total =
                  ratings.fold<double>(0, (s, r) => s + r.rating);
              return FarmerRatingSummary(
                averageRating:
                    ratings.isEmpty ? 0 : total / ratings.length,
                totalRatings: ratings.length,
                ratings: ratings,
              );
            }
          }
        }
      } catch (_) {}
    }
    return FarmerRatingSummary(
        averageRating: 0, totalRatings: 0, ratings: []);
  }

  // ── SUBMIT rating ────────────────────────────────────────────────
  // Tries multiple common endpoint patterns since we can't inspect the
  // backend URLs directly.
  static Future<void> submitRating({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    final body = jsonEncode({
      'product': productId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      // Some backends also accept 'stars' or 'score'
      'stars': rating,
      'score': rating,
    });

    final urls = [
      '$_base/ratings/',
      '$_base/ratings',
      '$_base/products/$productId/ratings/',
      '$_base/reviews/',
    ];

    for (final url in urls) {
      try {
        final r = await http.post(
          Uri.parse(url),
          headers: _headers,
          body: body,
        );
        if (r.statusCode == 200 ||
            r.statusCode == 201 ||
            r.statusCode == 202) {
          return; // success
        }
        // 400 usually means validation error (already reviewed, etc.)
        if (r.statusCode == 400) {
          final err = jsonDecode(r.body);
          throw Exception(
              err is Map ? err.values.first.toString() : r.body);
        }
      } catch (e) {
        if (e is Exception) rethrow;
        // Network error — try next URL
      }
    }
    throw Exception(
        'Could not submit review. Please check your connection and try again.');
  }
}