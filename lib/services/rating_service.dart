import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/rating.dart';

class RatingService {
  static const String _baseUrl =
      'https://josephkiarie2.pythonanywhere.com/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.getToken()}',
      };

  /// Fetch all ratings for a specific product
  static Future<List<Rating>> getProductRatings(int productId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/ratings/?product=$productId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((r) => Rating.fromJson(r)).toList();
    }
    throw Exception('Failed to load ratings: ${response.statusCode}');
  }

  /// Fetch farmer-level rating summary (average + list).
  /// Pass farmerId if known; if omitted, falls back to the
  /// authenticated farmer's own ratings endpoint.
  static Future<FarmerRatingSummary> getFarmerRatings(
      {int? farmerId}) async {
    final url = farmerId != null
        ? '$_baseUrl/ratings/farmer/$farmerId/'
        : '$_baseUrl/ratings/my-ratings/';

    final response =
        await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Backend may return a plain list OR a summary object
      if (data is List) {
        final ratings = data.map((r) => Rating.fromJson(r)).toList();
        final total = ratings.fold<double>(0, (s, r) => s + r.rating);
        return FarmerRatingSummary(
          averageRating: ratings.isEmpty ? 0 : total / ratings.length,
          totalRatings: ratings.length,
          ratings: ratings,
        );
      }
      return FarmerRatingSummary.fromJson(data);
    }
    throw Exception('Failed to load farmer ratings: ${response.statusCode}');
  }

  /// Submit a rating for a product
  static Future<void> submitRating({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/ratings/'),
      headers: _headers,
      body: jsonEncode({
        'product': productId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit rating: ${response.body}');
    }
  }
}