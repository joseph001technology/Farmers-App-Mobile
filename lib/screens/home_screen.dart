// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'products_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'farmer_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> featuredProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    try {
      final all = await ProductService.getProducts();
      setState(() {
        featuredProducts = all.take(4).toList();
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = AuthService.username ?? "Farmer";
    final isFarmer = AuthService.role == 'farmer';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.green[800],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green[900]!,
                          Colors.green[600]!,
                          Colors.teal[400]!,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20, left: -30,
                    child: Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          const Text("🌾 ", style: TextStyle(fontSize: 28)),
                          Text("FreshFarm",
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ]),
                        const SizedBox(height: 6),
                        Text("Good morning, $username 👋",
                            style: GoogleFonts.poppins(
                                fontSize: 15, color: Colors.white70)),
                        const SizedBox(height: 10),
                        // ── Farmer dashboard quick-link ─────────────
                        if (isFarmer)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const FarmerDashboardScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.amber.withOpacity(0.6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bar_chart,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 6),
                                  Text("View My Dashboard",
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.amber[100],
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text("🇰🇪  Nairobi, Kenya  •  Farm to Table",
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Dashboard icon in AppBar for farmers
              if (isFarmer)
                IconButton(
                  icon: const Icon(Icons.dashboard_outlined,
                      color: Colors.amber),
                  tooltip: 'My Dashboard',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FarmerDashboardScreen()),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Farmer dashboard banner ─────────────────────────
                if (isFarmer)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FarmerDashboardScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[800]!,
                              Colors.teal[600]!
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bar_chart,
                                color: Colors.white, size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Farmer Dashboard",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  Text(
                                      "View your sales, revenue & top products",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Stats row ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(16, isFarmer ? 16 : 20, 16, 0),
                  child: Row(
                    children: [
                      _statCard("🥬", "Fresh Daily", "Harvested today"),
                      const SizedBox(width: 10),
                      _statCard("🚚", "Fast Delivery", "Same day"),
                      const SizedBox(width: 10),
                      _statCard("🌱", "100% Organic", "No chemicals"),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── About section ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green[100],
                          child: const Text("🧑‍🌾",
                              style: TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Joseph Kiarie",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text("Organic Farmer • Nairobi",
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.green[700])),
                              const SizedBox(height: 8),
                              Text(
                                "Everything here is harvested fresh and delivered straight from my farm — no middlemen, just pure goodness ❤️",
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.5),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.phone, size: 16),
                                  label: const Text("Call Joseph"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Today's Picks ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Today's Picks 🌽",
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ProductsScreen())),
                        child: Text("See all",
                            style: GoogleFonts.poppins(
                                color: Colors.green[700])),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Featured products horizontal list ────────────────
                SizedBox(
                  height: 220,
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.green))
                      : featuredProducts.isEmpty
                          ? Center(
                              child: Text("No products yet",
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey)))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: featuredProducts.length,
                              itemBuilder: (context, index) {
                                final product = featuredProducts[index];
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailScreen(product: product),
                                    ),
                                  ),
                                  child: Container(
                                    width: 150,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.06),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3))
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(16)),
                                          child: product.imageUrl != null &&
                                                  product.imageUrl!.isNotEmpty
                                              ? Image.network(
                                                  product.imageUrl!,
                                                  height: 110,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) =>
                                                      _imagePlaceholder(),
                                                )
                                              : _imagePlaceholder(),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(product.name,
                                                  style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              Text(
                                                "KSh ${product.price.toStringAsFixed(0)}",
                                                style: GoogleFonts.poppins(
                                                    color: Colors.green[700],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13),
                                              ),
                                              // ── Rating stars ──────
                                              if (product.averageRating !=
                                                  null)
                                                Row(children: [
                                                  const Icon(Icons.star,
                                                      color: Colors.amber,
                                                      size: 13),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    product.averageRating!
                                                        .toStringAsFixed(1),
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                                ]),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),

                const SizedBox(height: 28),

                // ── Why FreshFarm ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Why FreshFarm? 🌿",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    _reasonTile("🌱", "100% Organic",
                        "No pesticides, no chemicals — just clean soil and sunshine."),
                    _reasonTile("🚚", "Same-Day Delivery",
                        "Order before noon and get it at your door by evening."),
                    _reasonTile("💰", "Fair Prices",
                        "Direct from farmer means no middlemen markup."),
                    _reasonTile("❤️", "Community First",
                        "Every purchase supports a local Nairobi family farm."),
                  ]),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProductsScreen())),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.store, color: Colors.white),
        label: Text("Shop Now",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _statCard(String emoji, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          Text(subtitle,
              style:
                  GoogleFonts.poppins(fontSize: 9, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _reasonTile(String emoji, String title, String subtitle) {
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
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle,
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ]),
        ),
      ]),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 110,
      color: Colors.green[50],
      child: const Center(
          child: Icon(Icons.grass, color: Colors.green, size: 36)),
    );
  }
}