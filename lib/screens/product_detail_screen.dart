import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/rating.dart';
import '../providers/cart_provider.dart';
import '../services/rating_service.dart';
import 'ratings_screen.dart';
import 'submit_rating_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Rating> _farmerRatings     = [];
  double       _farmerAvgRating   = 0;
  int          _farmerTotalRatings = 0;
  bool         _ratingsLoading    = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerRatings();
  }

  Future<void> _loadFarmerRatings() async {
    final farmerId = widget.product.farmerId;
    if (farmerId == null) {
      setState(() => _ratingsLoading = false);
      return;
    }
    try {
      final summary = await RatingService.getFarmerRatingById(farmerId);
      setState(() {
        _farmerRatings      = summary.ratings.take(5).toList();
        _farmerAvgRating    = summary.averageRating;
        _farmerTotalRatings = summary.totalRatings;
        _ratingsLoading     = false;
      });
    } catch (_) {
      setState(() => _ratingsLoading = false);
    }
  }

  // Navigate to SubmitRatingScreen with this farmer preselected
  Future<void> _goRate() async {
    final farmerId   = widget.product.farmerId;
    final farmerName = widget.product.farmerName;
    if (farmerId == null) return;

    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitRatingScreen(
          preselectedFarmerId:   farmerId,
          preselectedFarmerName: farmerName,
        ),
      ),
    );
    if (submitted == true) _loadFarmerRatings();
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart    = Provider.of<CartProvider>(context, listen: false);
    final product = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _imageFallback())
                  : _imageFallback(),
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () {}),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name + category ────────────────────────────
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Text(product.name,
                          style: GoogleFonts.poppins(
                              fontSize: 26, fontWeight: FontWeight.bold)),
                    ),
                    if (product.category != null &&
                        product.category!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(product.category!,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w600)),
                      ),
                  ]),

                  const SizedBox(height: 8),

                  // Price
                  Text(
                    'KSh ${product.price.toStringAsFixed(0)} ${product.unit ?? ''}',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // Product star rating
                  if (product.averageRating != null &&
                      product.averageRating! > 0)
                    Row(children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < product.averageRating!.floor()
                              ? Icons.star_rounded
                              : (i < product.averageRating!
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded),
                          color: Colors.amber, size: 20,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${product.averageRating!.toStringAsFixed(1)} • ${product.ratingCount ?? 0} reviews',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    ]),

                  const SizedBox(height: 14),

                  // Info chips
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (product.farmerName != null &&
                        product.farmerName!.isNotEmpty)
                      _infoChip('🧑‍🌾', product.farmerName!,
                          Colors.teal[50]!, Colors.teal[700]!),
                    if (product.harvestDate != null &&
                        product.harvestDate!.isNotEmpty)
                      _infoChip(
                          '📅',
                          'Harvested: ${_formatDate(product.harvestDate!)}',
                          Colors.orange[50]!,
                          Colors.orange[700]!),
                    if (product.stock != null)
                      _infoChip(
                        '📦',
                        '${product.stock} in stock',
                        product.stock! > 5
                            ? Colors.green[50]!
                            : Colors.red[50]!,
                        product.stock! > 5
                            ? Colors.green[700]!
                            : Colors.red[700]!,
                      ),
                  ]),

                  const SizedBox(height: 20),

                  // Description
                  Text('Description',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(product.description,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey[700])),

                  const SizedBox(height: 28),

                  // ── FARMER REVIEWS SECTION ─────────────────────
                  _farmerReviewsSection(product),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Add to Cart
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                cart.addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${product.name} added to cart! 🛒'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                'Add to Cart  •  KSh ${product.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Farmer Reviews Section ──────────────────────────────────────────
  Widget _farmerReviewsSection(Product product) {
    final farmerId   = product.farmerId;
    final farmerName = product.farmerName ?? 'Farmer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Farmer Reviews ⭐',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            Text('What customers say about $farmerName',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey[500])),
          ]),
          if (farmerId != null)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingsScreen(
                      farmerId: farmerId, farmerName: farmerName),
                ),
              ),
              child: Text('See all',
                  style: GoogleFonts.poppins(color: Colors.green[700])),
            ),
        ]),
        const SizedBox(height: 12),

        // Farmer profile strip
        if (farmerId != null) _farmerProfileStrip(product),
        const SizedBox(height: 14),

        // ── "Rate this Farmer" button ────────────────────────────
        if (farmerId != null) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _goRate,
              icon: const Icon(Icons.rate_review_rounded),
              label: Text(
                'Rate this Farmer',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green[700],
                side: BorderSide(color: Colors.green[400]!, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Ratings content
        if (_ratingsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: CircularProgressIndicator(color: Colors.green)),
          )
        else if (_farmerRatings.isEmpty)
          _noReviewsCard(farmerName)
        else
          ..._farmerRatings.map(_farmerReviewCard),
      ],
    );
  }

  Widget _farmerProfileStrip(Product product) {
    final initials = (product.farmerName ?? '?').isNotEmpty
        ? (product.farmerName ?? '?')[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.green[700]!, Colors.teal[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withOpacity(0.25),
          child: Text(initials,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Text(product.farmerName ?? 'Farmer',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(width: 5),
              const Icon(Icons.verified,
                  color: Colors.greenAccent, size: 14),
            ]),
            Text(product.farmerLocation ?? 'Nairobi, Kenya',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < _farmerAvgRating.floor()
                      ? Icons.star_rounded
                      : (i < _farmerAvgRating
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded),
                  color: Colors.amber, size: 14,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _farmerTotalRatings == 0
                    ? 'No reviews yet'
                    : '${_farmerAvgRating.toStringAsFixed(1)} ($_farmerTotalRatings reviews)',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 11),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _farmerReviewCard(Rating r) {
    final initials = r.consumerName.isNotEmpty
        ? r.consumerName[0].toUpperCase()
        : '?';
    final dateStr = r.createdAt.length >= 10
        ? r.createdAt.substring(0, 10)
        : r.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
            backgroundColor: Colors.teal[100],
            child: Text(initials,
                style: GoogleFonts.poppins(
                    color: Colors.teal[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(r.consumerName,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(dateStr,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey[400])),
            ]),
          ),
          Row(children: List.generate(
            5,
            (i) => Icon(
              i < r.stars
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: Colors.amber, size: 14,
            ),
          )),
        ]),
        if (r.review != null && r.review!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.format_quote,
                color: Colors.green[300], size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(r.review!,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                      height: 1.4)),
            ),
          ]),
        ] else ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.format_quote,
                color: Colors.green[200], size: 16),
            const SizedBox(width: 6),
            Text('${_starLabel(r.stars)} — great experience!',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic)),
          ]),
        ],
      ]),
    );
  }

  String _starLabel(int stars) {
    switch (stars) {
      case 5:  return 'Excellent';
      case 4:  return 'Great';
      case 3:  return 'Good';
      case 2:  return 'Fair';
      default: return 'Poor';
    }
  }

  Widget _noReviewsCard(String farmerName) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      const Text('⭐', style: TextStyle(fontSize: 36)),
      const SizedBox(height: 10),
      Text('No reviews for $farmerName yet',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 14)),
      Text('Be the first to review after your order is delivered!',
          style: GoogleFonts.poppins(
              color: Colors.grey[500], fontSize: 12),
          textAlign: TextAlign.center),
    ]),
  );

  Widget _imageFallback() => Container(
    color: Colors.green[100],
    child: const Center(
        child: Icon(Icons.grass, size: 80, color: Colors.green)),
  );

  Widget _infoChip(
      String emoji, String label, Color bg, Color textColor) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}