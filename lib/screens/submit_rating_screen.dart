import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../services/rating_service.dart';

class SubmitRatingScreen extends StatefulWidget {
  final Order order;

  const SubmitRatingScreen({super.key, required this.order});

  @override
  State<SubmitRatingScreen> createState() => _SubmitRatingScreenState();
}

class _SubmitRatingScreenState extends State<SubmitRatingScreen> {
  // Map productId -> selected star rating
  final Map<int, int> _ratings = {};
  final Map<int, TextEditingController> _comments = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize ratings and comment controllers for each item
    for (final item in widget.order.items ?? []) {
      _ratings[item.productId] = 0;
      _comments[item.productId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitRatings() async {
    // Ensure all products have been rated
    final unrated =
        _ratings.values.where((r) => r == 0).length;
    if (unrated > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Please rate all $unrated product${unrated == 1 ? '' : 's'} before submitting.",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      for (final entry in _ratings.entries) {
        await RatingService.submitRating(
          productId: entry.key,
          rating: entry.value,
          comment: _comments[entry.key]?.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text("Reviews submitted! Thank you ⭐",
                style: GoogleFonts.poppins()),
          ]),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting review: $e",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.order.items ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text("Rate Your Order",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[700]!, Colors.amber[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text("⭐", style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "How was Order #${widget.order.id}?",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      Text(
                        "Rate each product from your delivery",
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (items.isEmpty)
            Center(
              child: Text(
                "No products found in this order.",
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            )
          else
            ...items.map((item) => _productRatingCard(item)),

          const SizedBox(height: 20),

          if (items.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitRatings,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? "Submitting..." : "Submit Reviews",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _productRatingCard(OrderItem item) {
    final selectedRating = _ratings[item.productId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            item.productName ?? "Product #${item.productId}",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            "Qty: ${item.quantity}",
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
          ),

          const SizedBox(height: 12),

          // Star rating selector
          Row(
            children: [
              Text("Your rating: ",
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[700])),
              const Spacer(),
              Row(
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _ratings[item.productId] = starValue),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        starValue <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: starValue <= selectedRating
                            ? Colors.amber
                            : Colors.grey[400],
                        size: 30,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Comment field
          TextField(
            controller: _comments[item.productId],
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Leave a comment (optional)...",
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.green[400]!),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
