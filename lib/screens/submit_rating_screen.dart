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
  final Map<int, int> _ratings = {};
  final Map<int, TextEditingController> _comments = {};
  final Map<int, bool> _submitted = {}; // track per-product submission
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.orderItems) {
      _ratings[item.productId] = 0;
      _comments[item.productId] = TextEditingController();
      _submitted[item.productId] = false;
    }
  }

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitAll() async {
    final unrated = _ratings.entries
        .where((e) => e.value == 0 && !(_submitted[e.key] ?? false))
        .length;
    if (unrated > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Please tap the stars to rate all $unrated product${unrated == 1 ? '' : 's'}.",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    int successCount = 0;
    final List<String> errors = [];

    for (final item in widget.order.orderItems) {
      if (_submitted[item.productId] == true) continue;
      final stars = _ratings[item.productId] ?? 0;
      if (stars == 0) continue;

      try {
        await RatingService.submitRating(
          productId: item.productId,
          rating: stars,
          comment: _comments[item.productId]?.text.trim(),
        );
        setState(() => _submitted[item.productId] = true);
        successCount++;
      } catch (e) {
        errors.add('${item.productName}: $e');
      }
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                successCount == 1
                    ? "Review submitted! Thank you ⭐"
                    : "$successCount reviews submitted! Thank you ⭐",
                style: GoogleFonts.poppins(),
              ),
            ),
          ]),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } else {
      // Some succeeded, some failed
      final msg = successCount > 0
          ? "$successCount submitted. Issues:\n${errors.join('\n')}"
          : errors.join('\n');
      _showErrorDialog(msg);
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Review Status",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(msg,
              style: GoogleFonts.poppins(fontSize: 13, height: 1.5)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white),
            child: Text("OK", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.order.orderItems;

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
          // Header banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[700]!, Colors.orange[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text("⭐", style: TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
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
                        "Tap the stars to rate each product",
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    "No products found in this order.",
                    style: GoogleFonts.poppins(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "The order detail may not have loaded yet.",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...items.map((item) => _ratingCard(item)),

          const SizedBox(height: 20),

          if (items.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitAll,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
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

  Widget _ratingCard(OrderItem item) {
    final selected = _ratings[item.productId] ?? 0;
    final alreadyDone = _submitted[item.productId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alreadyDone ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: alreadyDone
            ? Border.all(color: Colors.green[300]!)
            : Border.all(color: Colors.transparent),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      "Qty: ${item.quantity}",
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (alreadyDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[700], size: 14),
                      const SizedBox(width: 4),
                      Text("Reviewed",
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Star selector
          if (!alreadyDone) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starVal = i + 1;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _ratings[item.productId] = starVal),
                  child: AnimatedScale(
                    scale: selected == starVal ? 1.25 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        starVal <= selected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: starVal <= selected
                            ? Colors.amber
                            : Colors.grey[300],
                        size: 38,
                      ),
                    ),
                  ),
                );
              }),
            ),

            if (selected > 0) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  ['', 'Poor 😞', 'Fair 😐', 'Good 🙂', 'Great 😄',
                      'Excellent 🌟'][selected],
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Comment
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
          ] else ...[
            // Show submitted stars read-only
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < selected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 28,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}