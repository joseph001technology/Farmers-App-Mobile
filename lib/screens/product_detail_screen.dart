import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/rating.dart';
import '../providers/cart_provider.dart';
import '../services/rating_service.dart';
import 'ratings_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Rating> ratings = [];
  bool ratingsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      final result =
          await RatingService.getProductRatings(widget.product.id);
      setState(() {
        ratings = result.take(3).toList();
        ratingsLoading = false;
      });
    } catch (_) {
      setState(() => ratingsLoading = false);
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return "${dt.day} ${months[dt.month]} ${dt.year}";
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final product = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.green[800],
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.green[100],
                        child: const Center(
                            child: Icon(Icons.grass,
                                size: 80, color: Colors.green)),
                      ),
                    )
                  : Container(
                      color: Colors.green[100],
                      child: const Center(
                          child: Icon(Icons.grass,
                              size: 80, color: Colors.green)),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Category badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (product.category != null &&
                          product.category!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            product.category!,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Price
                  Text(
                    "KSh ${product.price.toStringAsFixed(0)} ${product.unit ?? ''}",
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // Star rating
                  if (product.averageRating != null &&
                      product.averageRating! > 0)
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < product.averageRating!.floor()
                                ? Icons.star_rounded
                                : (i < product.averageRating!
                                    ? Icons.star_half_rounded
                                    : Icons.star_outline_rounded),
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${product.averageRating!.toStringAsFixed(1)} • ${product.ratingCount ?? 0} reviews",
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),

                  const SizedBox(height: 14),

                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (product.farmerName != null &&
                          product.farmerName!.isNotEmpty)
                        _infoChip("🧑‍🌾", product.farmerName!,
                            Colors.teal[50]!, Colors.teal[700]!),
                      if (product.harvestDate != null &&
                          product.harvestDate!.isNotEmpty)
                        _infoChip(
                            "📅",
                            "Harvested: ${_formatDate(product.harvestDate!)}",
                            Colors.orange[50]!,
                            Colors.orange[700]!),
                      if (product.stock != null)
                        _infoChip(
                            "📦",
                            "${product.stock} in stock",
                            product.stock! > 5
                                ? Colors.green[50]!
                                : Colors.red[50]!,
                            product.stock! > 5
                                ? Colors.green[700]!
                                : Colors.red[700]!),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Text(
                    "Description",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 24),

                  // Reviews section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Customer Reviews ⭐",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RatingsScreen(
                              productId: product.id,
                              productName: product.name,
                            ),
                          ),
                        ),
                        child: Text("See all",
                            style: GoogleFonts.poppins(
                                color: Colors.green[700])),
                      ),
                    ],
                  ),

                  if (ratingsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.green)),
                    )
                  else if (ratings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text("⭐",
                              style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text("No reviews yet",
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    "Be the first to rate this product!",
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...ratings.map((r) => _ratingCard(r)),

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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text("${product.name} added to cart! 🛒"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                "Add to Cart  •  KSh ${product.price.toStringAsFixed(0)}",
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

  Widget _infoChip(
      String emoji, String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _ratingCard(Rating r) {
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
                radius: 16,
                backgroundColor: Colors.green[100],
                child: Text(
                  (r.consumerName ?? "U")[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.consumerName ?? "Anonymous",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13),
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
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.comment!,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}