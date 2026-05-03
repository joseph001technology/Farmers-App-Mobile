import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'products_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'farmer_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'ratings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> allProducts = [];
  bool isLoading = true;

  // Group products by farmer name
  Map<String, List<Product>> get _byFarmer {
    final Map<String, List<Product>> map = {};
    for (final p in allProducts) {
      final key = p.farmerName ?? 'Unknown Farmer';
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  // Today's picks = first 6 products
  List<Product> get _todaysPicks => allProducts.take(6).toList();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final all = await ProductService.getProducts();
      setState(() {
        allProducts = all;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Widget _dashboardScreen(bool isAdmin) =>
      isAdmin ? const AdminDashboardScreen() : const FarmerDashboardScreen();

  @override
  Widget build(BuildContext context) {
    final username = AuthService.username ?? "Farmer";
    final role = AuthService.role ?? "";
    final isFarmer = role == 'farmer';
    final isAdmin = role == 'admin';
    final farmerGroups = _byFarmer;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: Colors.green,
        child: CustomScrollView(
          slivers: [
            // ── Hero App Bar ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 240,
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
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Text("🌾 ",
                                  style: TextStyle(fontSize: 26)),
                              Text(
                                "FreshFarm",
                                style: GoogleFonts.playfairDisplay(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Good morning, $username 👋",
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _heroBadge(
                                  "🇰🇪  Nairobi, Kenya  •  Farm to Table"),
                              if (isFarmer || isAdmin)
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            _dashboardScreen(isAdmin)),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.dashboard,
                                            color: Colors.white, size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          isAdmin ? "Admin" : "Dashboard",
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
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
                  // ── Stats row ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      children: [
                        _statCard("🥬", "Fresh Daily", "Harvested today"),
                        const SizedBox(width: 10),
                        _statCard("🚚", "Fast Delivery", "Same day"),
                        const SizedBox(width: 10),
                        _statCard("🌾", "${farmerGroups.length} Farmers",
                            "On platform"),
                      ],
                    ),
                  ),

                  // ── Dashboard banner (farmer/admin only) ─────────────
                  if (isFarmer || isAdmin) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange[700]!,
                              Colors.orange[400]!
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Text("📊",
                                style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAdmin
                                        ? "Admin Dashboard"
                                        : "Farmer Dashboard",
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  Text(
                                    isAdmin
                                        ? "Platform analytics & reports"
                                        : "Track your sales & revenue",
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        _dashboardScreen(isAdmin)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orange[700],
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text("Open",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── TODAY'S PICKS (horizontal scroll) ──────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Today's Picks 🌽",
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProductsScreen()),
                          ),
                          child: Text("See all",
                              style: GoogleFonts.poppins(
                                  color: Colors.green[700])),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    height: 230,
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Colors.green))
                        : _todaysPicks.isEmpty
                            ? Center(
                                child: Text("No products yet",
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey)))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                itemCount: _todaysPicks.length,
                                itemBuilder: (context, index) {
                                  return _productCard(
                                      _todaysPicks[index]);
                                },
                              ),
                  ),

                  const SizedBox(height: 28),

                  // ── FARMERS SECTION ─────────────────────────────────
                  if (!isLoading && farmerGroups.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Our Farmers 🧑‍🌾",
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "${farmerGroups.length} local farmers, ${allProducts.length} products",
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // One section per farmer
                    ...farmerGroups.entries.map((entry) {
                      final farmerName = entry.key;
                      final farmerProducts = entry.value;
                      // Grab extra info from first product
                      final sample = farmerProducts.first;
                      return _farmerSection(
                          farmerName, farmerProducts, sample);
                    }),
                  ],

                  const SizedBox(height: 28),

                  // ── WHY FRESHFARM ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Why FreshFarm? 🌿",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _reasonTile("🌱", "100% Organic",
                            "No pesticides, no chemicals — just clean soil and sunshine."),
                        _reasonTile("🚚", "Same-Day Delivery",
                            "Order before noon and get it at your door by evening."),
                        _reasonTile("💰", "Fair Prices",
                            "Direct from farmer means no middlemen markup."),
                        _reasonTile("❤️", "Community First",
                            "Every purchase supports a local Nairobi family farm."),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductsScreen()),
        ),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.store, color: Colors.white),
        label: Text("Shop Now",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── FARMER SECTION ────────────────────────────────────────────────
  Widget _farmerSection(
      String farmerName, List<Product> products, Product sample) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Farmer header card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green[100],
                  child: Text(
                    farmerName.isNotEmpty ? farmerName[0].toUpperCase() : '🌾',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800]),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(farmerName,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        sample.farmerLocation ?? "Nairobi, Kenya",
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.green[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${products.length} product${products.length == 1 ? '' : 's'} available",
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                      // Rating if available
                      if (sample.averageRating != null &&
                          sample.averageRating! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < sample.averageRating!.floor()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sample.averageRating!.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Call / Reviews buttons
                Column(
                  children: [
                    if (sample.farmerPhone != null)
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone, size: 13),
                        label: const Text("Call"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[700],
                          side: BorderSide(color: Colors.green[300]!),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          textStyle: GoogleFonts.poppins(fontSize: 11),
                        ),
                      ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RatingsScreen()),
                      ),
                      icon: const Icon(Icons.star_outline, size: 13),
                      label: const Text("Reviews"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        textStyle: GoogleFonts.poppins(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Farmer's products horizontal scroll
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 4),
            itemCount: products.length,
            itemBuilder: (context, index) =>
                _productCard(products[index], showFarmer: false),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ── PRODUCT CARD ──────────────────────────────────────────────────
  Widget _productCard(Product product, {bool showFarmer = true}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      height: 108,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Farmer name under product
                  if (showFarmer && product.farmerName != null)
                    Text(
                      "by ${product.farmerName}",
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.green[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    "KSh ${product.price.toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  // Stars if rated
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
                            size: 11,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.averageRating!.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              fontSize: 9, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 108,
      color: Colors.green[50],
      child: const Center(
          child: Icon(Icons.grass, color: Colors.green, size: 36)),
    );
  }

  Widget _heroBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
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
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 9, color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ],
        ),
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
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}