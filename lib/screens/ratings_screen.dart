import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/rating_service.dart';
import '../models/rating.dart';

class RatingsScreen extends StatefulWidget {
  final int? productId;
  final String? productName;
  final String? farmerName;

  const RatingsScreen({
    super.key,
    this.productId,
    this.productName,
    this.farmerName,
  });

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  List<Rating> ratings = [];
  bool isLoading = true;
  double averageRating = 0;
  String errorMessage = '';

  // ── Submit form state ──────────────────────────────────────────────
  int _selectedStars = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _showForm = false; // toggled by FAB / button

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRatings() async {
    setState(() { isLoading = true; errorMessage = ''; });
    try {
      if (widget.productId != null) {
        final result = await RatingService.getProductRatings(widget.productId!);
        final total  = result.fold<double>(0, (s, r) => s + r.rating);
        setState(() {
          ratings       = result;
          averageRating = result.isEmpty ? 0 : total / result.length;
          isLoading     = false;
        });
      } else {
        final summary = await RatingService.getFarmerRatings();
        setState(() {
          ratings       = summary.ratings;
          averageRating = summary.averageRating;
          isLoading     = false;
        });
      }
    } catch (e) {
      setState(() { errorMessage = e.toString(); isLoading = false; });
    }
  }

  // ── Submit a new rating ───────────────────────────────────────────
  Future<void> _submitRating() async {
    // Can only submit when viewing a specific product
    if (widget.productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please open a product page to leave a review.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await RatingService.submitRating(
        productId: widget.productId!,
        rating: _selectedStars,
        comment: _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
      );

      // Reset form
      _commentCtrl.clear();
      setState(() {
        _selectedStars = 5;
        _showForm = false;
        _submitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submitted! Thank you 🌟',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.green[700],
          ),
        );
      }

      // Reload to show the new review
      await _loadRatings();
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''),
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  String get _title {
    if (widget.farmerName != null && widget.farmerName!.isNotEmpty) {
      return '${widget.farmerName} Reviews';
    }
    if (widget.productName != null && widget.productName!.isNotEmpty) {
      return '${widget.productName} Reviews';
    }
    return 'All Reviews';
  }

  // Only show "Write a review" button when a product is targeted
  bool get _canReview => widget.productId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text(_title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadRatings),
        ],
      ),

      // ── FAB: Write a Review (only when productId is provided) ──────
      floatingActionButton: _canReview
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showForm = !_showForm),
              backgroundColor: Colors.green[700],
              icon: Icon(_showForm ? Icons.close : Icons.rate_review_rounded),
              label: Text(_showForm ? 'Cancel' : 'Write a Review',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            )
          : null,

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green))
          : errorMessage.isNotEmpty
              ? _errorView()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [

                    // ── Inline submit form (shown when FAB tapped) ────
                    if (_showForm && _canReview) ...[
                      _submitForm(),
                      const SizedBox(height: 20),
                    ],

                    // ── Empty state ───────────────────────────────────
                    if (ratings.isEmpty) ...[
                      _emptyView(),
                    ] else ...[
                      // ── Summary card ────────────────────────────────
                      _summaryCard(),
                      const SizedBox(height: 16),

                      // ── Review cards ────────────────────────────────
                      ...ratings.map((r) => _reviewCard(r)),
                    ],
                  ],
                ),
    );
  }

  // ── Submit form ───────────────────────────────────────────────────
  Widget _submitForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Write your review',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.green[800])),
        const SizedBox(height: 4),
        if (widget.productName != null)
          Text('for ${widget.productName}',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[500])),

        const SizedBox(height: 16),

        // Star selector
        Text('Your rating',
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _selectedStars = star),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  star <= _selectedStars
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 36,
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_selectedStars],
            style: GoogleFonts.poppins(
                color: Colors.amber[700],
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ),

        const SizedBox(height: 16),

        // Comment field
        Text('Comment (optional)',
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 6),
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Share your experience with this product…',
            hintStyle:
                GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
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
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitRating,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Submit Review',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────
  Widget _summaryCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.amber[700]!, Colors.amber[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(averageRating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
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
                        ))),
            const SizedBox(height: 4),
            Text(
                '${ratings.length} review${ratings.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 13)),
          ]),
          const Spacer(),
          // Distribution bars
          Column(
              children: List.generate(5, (i) {
            final star  = 5 - i;
            final count = ratings.where((r) => r.rating == star).length;
            final pct   = ratings.isEmpty ? 0.0 : count / ratings.length;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Text('$star',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Colors.white, size: 12),
                const SizedBox(width: 6),
                SizedBox(
                  width: 80,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.white30,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('$count',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 11)),
              ]),
            );
          })),
        ]),
      );

  // ── Single review card ────────────────────────────────────────────
  Widget _reviewCard(Rating r) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green[100],
              child: Text((r.consumerName ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Text(r.consumerName ?? 'Anonymous',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              if (r.productName != null)
                Text(r.productName!,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[500])),
              if (r.createdAt.isNotEmpty)
                Text(
                  r.createdAt.length > 10
                      ? r.createdAt.substring(0, 10)
                      : r.createdAt,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey[400]),
                ),
            ])),
            Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < r.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 16,
                        ))),
          ]),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.comment!,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5)),
          ],
        ]),
      );

  Widget _errorView() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Could not load reviews',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(errorMessage,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadRatings,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white),
          ),
        ]),
      );

  Widget _emptyView() => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('⭐', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text('No reviews yet',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Be the first to leave a review!',
                style: GoogleFonts.poppins(color: Colors.grey[600])),
            if (_canReview) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showForm = true),
                icon: const Icon(Icons.rate_review_rounded),
                label: Text('Write a Review',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ]),
        ),
      );
}