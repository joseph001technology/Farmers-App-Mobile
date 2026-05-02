import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/rating_service.dart';
import '../models/rating.dart';

class RatingsScreen extends StatefulWidget {
  final int? productId;
  final String? productName;

  const RatingsScreen({super.key, this.productId, this.productName});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  List<Rating> ratings = [];
  bool isLoading = true;
  double averageRating = 0;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      final result = widget.productId != null
          ? await RatingService.getProductRatings(widget.productId!)
          : await RatingService.getFarmerRatings();

      final total = result.fold<double>(0, (sum, r) => sum + r.rating);
      setState(() {
        ratings = result;
        averageRating = result.isEmpty ? 0 : total / result.length;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text(
          widget.productName != null
              ? "${widget.productName} Reviews"
              : "All Reviews",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green))
          : ratings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("⭐", style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      Text(
                        "No reviews yet",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Be the first to leave a review!",
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary card
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber[700]!, Colors.amber[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < averageRating.floor()
                                        ? Icons.star_rounded
                                        : (i < averageRating
                                            ? Icons.star_half_rounded
                                            : Icons.star_outline_rounded),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${ratings.length} review${ratings.length == 1 ? '' : 's'}",
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Rating distribution
                          Column(
                            children: List.generate(5, (i) {
                              final star = 5 - i;
                              final count = ratings
                                  .where((r) => r.rating == star)
                                  .length;
                              final pct = ratings.isEmpty
                                  ? 0.0
                                  : count / ratings.length;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Text("$star",
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 12)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star,
                                        color: Colors.white, size: 12),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 80,
                                      height: 6,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          backgroundColor:
                                              Colors.white30,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text("$count",
                                        style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 11)),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    // Individual reviews
                    ...ratings.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.green[100],
                                    child: Text(
                                      (r.consumerName ?? "U")[0]
                                          .toUpperCase(),
                                      style: GoogleFonts.poppins(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.consumerName ?? "Anonymous",
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                        ),
                                        if (r.productName != null)
                                          Text(
                                            r.productName!,
                                            style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey[500]),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < r.rating
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (r.comment != null &&
                                  r.comment!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  r.comment!,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      height: 1.5),
                                ),
                              ],
                            ],
                          ),
                        )),
                  ],
                ),
    );
  }
}