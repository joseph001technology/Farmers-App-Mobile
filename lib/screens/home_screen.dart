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
import 'consumer_dashboard_screen.dart';
import 'ratings_screen.dart';
import 'farmer_profile_screen.dart';
import '../widgets/farmer_avatar.dart';
import '../helpers/farmer_nav_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> allProducts = [];
  bool isLoading = true;

  Map<String, List<Product>> get _byFarmer {
    final Map<String, List<Product>> map = {};
    for (final p in allProducts) {
      final key = p.farmerName ?? 'Unknown Farmer';
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  List<Product> get _todaysPicks => allProducts.take(6).toList();

  /// Farmers sorted by averageRating descending — only real farmers with data.
  /// Shows up to 5; pads with empty slots only if fewer than 5 real farmers.
  List<_FarmerSummary> get _topFarmers {
    final map = <int, _FarmerSummary>{};
    for (final p in allProducts) {
      final fId = p.farmerId;
      if (fId == null) continue;
      final name = p.farmerName ?? 'Unknown';
      if (!map.containsKey(fId)) {
        map[fId] = _FarmerSummary(
          name:           name,
          farmerId:       fId,
          avgRating:      p.averageRating ?? 0.0,
          ratingCount:    p.ratingCount   ?? 0,
          farmerLocation: p.farmerLocation,
          farmerPhoto:    p.farmerPhoto,
        );
      } else {
        // If this product has a higher rating, update
        final existing = map[fId]!;
        if ((p.averageRating ?? 0) > existing.avgRating) {
          map[fId] = _FarmerSummary(
            name:           existing.name,
            farmerId:       existing.farmerId,
            avgRating:      p.averageRating ?? existing.avgRating,
            ratingCount:    p.ratingCount   ?? existing.ratingCount,
            farmerLocation: existing.farmerLocation,
            farmerPhoto:    p.farmerPhoto ?? existing.farmerPhoto,
          );
        }
        // Also accumulate rating count
        final cur = map[fId]!;
        map[fId] = _FarmerSummary(
          name:           cur.name,
          farmerId:       cur.farmerId,
          avgRating:      cur.avgRating,
          ratingCount:    cur.ratingCount + (p.ratingCount ?? 0),
          farmerLocation: cur.farmerLocation,
          farmerPhoto:    cur.farmerPhoto,
        );
      }
    }

    final list = map.values.toList()
      ..sort((a, b) => b.avgRating.compareTo(a.avgRating));

    // Pad to 5 with placeholders only if we have fewer than 5
    while (list.length < 5) {
      list.add(_FarmerSummary(
          name: '—', farmerId: null,
          avgRating: 0, ratingCount: 0,
          farmerLocation: null, farmerPhoto: null));
    }
    return list.take(5).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  String _loadError = '';

  Future<void> _loadProducts() async {
    setState(() { isLoading = true; _loadError = ''; });
    try {
      final all = await ProductService.getProducts();
      setState(() { allProducts = all; isLoading = false; });
    } catch (e) {
      setState(() { isLoading = false; _loadError = e.toString(); });
    }
  }

  Widget _dashboardScreen(String role) {
    if (role == 'admin')  return const AdminDashboardScreen();
    if (role == 'farmer') return const FarmerDashboardScreen();
    return const ConsumerDashboardScreen();
  }

  void _goToFarmerProfile(_FarmerSummary f) {
    goToFarmerProfile(
      context,
      farmerId:       f.farmerId,
      farmerName:     f.name,
      farmerLocation: f.farmerLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final username     = AuthService.username ?? 'User';
    final role         = AuthService.role ?? '';
    final isFarmer     = role == 'farmer';
    final isAdmin      = role == 'admin';
    final farmerGroups = _byFarmer;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: Colors.green,
        child: CustomScrollView(
          slivers: [
            // ── Hero App Bar ───────────────────────────────────────
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
                          colors: [Colors.green[900]!, Colors.green[600]!, Colors.teal[400]!],
                        ),
                      ),
                    ),
                    Positioned(top: -40, right: -40,
                        child: _circle(180, Colors.white.withOpacity(0.06))),
                    Positioned(bottom: -20, left: -30,
                        child: _circle(140, Colors.white.withOpacity(0.06))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(children: [
                            const Text('🌾 ', style: TextStyle(fontSize: 26)),
                            Text('AgriFlow',
                                style: GoogleFonts.playfairDisplay(
                                    fontSize: 30, fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ]),
                          const SizedBox(height: 4),
                          Text('Good morning, $username 👋',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.white70)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 6, children: [
                            _heroBadge('🇰🇪  Nairobi, Kenya  •  Farm to Table'),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => _dashboardScreen(role))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? Colors.indigo.withOpacity(0.9)
                                      : isFarmer
                                          ? Colors.orange.withOpacity(0.9)
                                          : Colors.teal.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(
                                    isAdmin ? Icons.admin_panel_settings
                                        : isFarmer ? Icons.agriculture
                                        : Icons.dashboard_rounded,
                                    color: Colors.white, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAdmin ? 'Admin' : isFarmer ? 'Dashboard' : 'My Dashboard',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white, fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {}),
                IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CartScreen()))),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Error banner ───────────────────────────────────
                  if (_loadError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                              const SizedBox(width: 8),
                              Text('Could not load products',
                                  style: GoogleFonts.poppins(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ]),
                            const SizedBox(height: 4),
                            Text(_loadError,
                                style: GoogleFonts.poppins(
                                    color: Colors.red[600], fontSize: 11),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _loadProducts,
                              child: Text('Tap to retry →',
                                  style: GoogleFonts.poppins(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Stats row ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(children: [
                      _statCard('🥬', 'Fresh Daily', 'Harvested today'),
                      const SizedBox(width: 10),
                      _statCard('🚚', 'Fast Delivery', 'Same day'),
                      const SizedBox(width: 10),
                      _statCard('🌾', '${farmerGroups.length} Farmers', 'On platform'),
                    ]),
                  ),

                  // ── Dashboard banner ───────────────────────────────
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => _dashboardScreen(role))),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isAdmin
                                ? [Colors.indigo[700]!, Colors.indigo[400]!]
                                : isFarmer
                                    ? [Colors.orange[700]!, Colors.orange[400]!]
                                    : [Colors.teal[700]!, Colors.teal[400]!],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(children: [
                          Text(isAdmin ? '⚙️' : isFarmer ? '📊' : '🛍️',
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              isAdmin ? 'Admin Dashboard'
                                  : isFarmer ? 'Farmer Dashboard' : 'My Dashboard',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                            Text(
                              isAdmin ? 'Platform analytics & reports'
                                  : isFarmer ? 'Track your sales & revenue'
                                  : 'Orders, spending & top farmers',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 12)),
                          ])),
                          ElevatedButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => _dashboardScreen(role))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: isAdmin ? Colors.indigo[700]
                                  : isFarmer ? Colors.orange[700] : Colors.teal[700],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: Text('Open',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── TODAY'S PICKS ──────────────────────────────────
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
                              MaterialPageRoute(builder: (_) => const ProductsScreen())),
                          child: Text('See all',
                              style: GoogleFonts.poppins(color: Colors.green[700])),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 230,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.green))
                        : _todaysPicks.isEmpty
                            ? Center(child: Text('No products yet',
                                style: GoogleFonts.poppins(color: Colors.grey)))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _todaysPicks.length,
                                itemBuilder: (_, i) => _productCard(_todaysPicks[i]),
                              ),
                  ),

                  const SizedBox(height: 28),

                  // ── TOP REVIEWED FARMERS ───────────────────────────
                  if (!isLoading) _topReviewedFarmersSection(),

                  const SizedBox(height: 28),

                  // ── FARMERS SECTION ────────────────────────────────
                  if (!isLoading && farmerGroups.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Our Farmers 🧑‍🌾',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${farmerGroups.length} local farmers, ${allProducts.length} products',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...farmerGroups.entries.map((e) =>
                        _farmerSection(e.key, e.value, e.value.first)),
                  ],

                  const SizedBox(height: 28),

                  // ── WHY AGRIFLOW ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Why AgriFlow? 🌿',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      _reasonTile('🌱', '100% Organic',
                          'No pesticides, no chemicals — just clean soil and sunshine.'),
                      _reasonTile('🚚', 'Same-Day Delivery',
                          'Order before noon and get it at your door by evening.'),
                      _reasonTile('💰', 'Fair Prices',
                          'Direct from farmer means no middlemen markup.'),
                      _reasonTile('❤️', 'Community First',
                          'Every purchase supports a local Nairobi family farm.'),
                    ]),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProductsScreen())),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.store, color: Colors.white),
        label: Text('Shop Now',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── TOP REVIEWED FARMERS SECTION ──────────────────────────────────
  Widget _topReviewedFarmersSection() {
    final farmers = _topFarmers;
    // Check if we have any real farmers
    final hasRealFarmers = farmers.any((f) => f.farmerId != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Rated Farmers 🏆',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Text('Top 5',
                    style: GoogleFonts.poppins(
                        color: Colors.amber[800], fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Based on customer reviews',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[500])),
        ),
        const SizedBox(height: 12),
        if (!hasRealFarmers)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(child: Column(children: [
                const Text('🌾', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text('No ratings yet',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                Text('Be the first to review a farmer!',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[500], fontSize: 12)),
              ])),
            ),
          )
        else
          ...farmers.asMap().entries.map((entry) {
            final rank   = entry.key + 1;
            final farmer = entry.value;
            return _topFarmerRow(rank, farmer);
          }),
      ],
    );
  }

  Widget _topFarmerRow(int rank, _FarmerSummary f) {
    final medalEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
    final isEmpty    = f.farmerId == null;

    return GestureDetector(
      onTap: isEmpty ? null : () => _goToFarmerProfile(f),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: rank == 1
              ? Border.all(color: Colors.amber[300]!, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          // Rank badge
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.amber[50] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(
              rank <= 3 ? medalEmoji : '#$rank',
              style: TextStyle(fontSize: rank <= 3 ? 18 : 12),
            )),
          ),
          const SizedBox(width: 10),
          // Avatar with photo
          isEmpty
              ? CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[200],
                  child: Text('?',
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                )
              : FarmerAvatar(
                  farmerId:    f.farmerId,
                  farmerName:  f.name,
                  radius:      22,
                  onTap: () => _goToFarmerProfile(f),
                ),
          const SizedBox(width: 12),
          // Name + location + stars
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEmpty ? 'Not yet rated' : f.name,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14,
                    color: isEmpty ? Colors.grey[400] : Colors.black87)),
            if (!isEmpty && f.farmerLocation != null)
              Text(f.farmerLocation!,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.green[700]))
            else if (!isEmpty)
              Text('Nairobi, Kenya',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.green[700])),
            const SizedBox(height: 3),
            Row(children: [
              ...List.generate(5, (i) => Icon(
                i < f.avgRating.floor()
                    ? Icons.star_rounded
                    : (i < f.avgRating
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded),
                color: isEmpty ? Colors.grey[300] : Colors.amber,
                size: 13,
              )),
              const SizedBox(width: 4),
              Text(
                isEmpty
                    ? 'No reviews'
                    : f.avgRating > 0
                        ? '${f.avgRating.toStringAsFixed(1)} (${f.ratingCount})'
                        : 'No reviews yet',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isEmpty ? Colors.grey[400] : Colors.grey[600]),
              ),
            ]),
          ])),
          // Action buttons
          if (!isEmpty && f.farmerId != null)
            Column(children: [
              // View Profile
              GestureDetector(
                onTap: () => _goToFarmerProfile(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_outline, size: 12, color: Colors.green[700]),
                    const SizedBox(width: 3),
                    Text('Profile',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.green[700],
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(height: 4),
              // Reviews button
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RatingsScreen(
                        farmerId: f.farmerId, farmerName: f.name))),
                icon: const Icon(Icons.star_outline, size: 13),
                label: const Text('Reviews'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                  side: BorderSide(color: Colors.orange[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  textStyle: GoogleFonts.poppins(fontSize: 10),
                ),
              ),
            ]),
        ]),
      ),
    );
  }

  // ── FARMER SECTION ─────────────────────────────────────────────────
  Widget _farmerSection(String farmerName, List<Product> products, Product sample) {
    final farmerId = sample.farmerId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => goToFarmerProfile(
                context,
                farmerId:       farmerId,
                farmerName:     farmerName,
                farmerLocation: sample.farmerLocation,
              ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Profile photo avatar
                FarmerAvatar(
                  farmerId:   farmerId,
                  farmerName: farmerName,
                  radius:     28,
                  onTap: () => goToFarmerProfile(
                      context,
                      farmerId:       farmerId,
                      farmerName:     farmerName,
                      farmerLocation: sample.farmerLocation,
                    ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(farmerName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 4),
                    Icon(Icons.verified, color: Colors.green[400], size: 14),
                  ]),
                  Text(sample.farmerLocation ?? 'Nairobi, Kenya',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.green[700])),
                  const SizedBox(height: 4),
                  Text(
                    '${products.length} product${products.length == 1 ? '' : 's'} available',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500])),
                  if (sample.averageRating != null && sample.averageRating! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        ...List.generate(5, (i) => Icon(
                          i < sample.averageRating!.floor()
                              ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber, size: 14,
                        )),
                        const SizedBox(width: 4),
                        Text(sample.averageRating!.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey[600])),
                      ]),
                    ),
                ])),
                Column(children: [
                  if (sample.farmerPhone != null)
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone, size: 13),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        side: BorderSide(color: Colors.green[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        textStyle: GoogleFonts.poppins(fontSize: 11),
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (farmerId != null)
                    OutlinedButton.icon(
                      onPressed: () => goToFarmerProfile(
                          context,
                          farmerId:       farmerId,
                          farmerName:     farmerName,
                          farmerLocation: sample.farmerLocation,
                        ),
                      icon: const Icon(Icons.person_outline, size: 13),
                      label: const Text('Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal[700],
                        side: BorderSide(color: Colors.teal[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        textStyle: GoogleFonts.poppins(fontSize: 11),
                      ),
                    ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => RatingsScreen(
                            farmerId: farmerId, farmerName: farmerName))),
                    icon: const Icon(Icons.star_outline, size: 13),
                    label: const Text('Reviews'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(color: Colors.orange[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      textStyle: GoogleFonts.poppins(fontSize: 11),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
            itemCount: products.length,
            itemBuilder: (_, i) => _productCard(products[i], showFarmer: false),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── PRODUCT CARD ───────────────────────────────────────────────────
  Widget _productCard(Product product, {bool showFarmer = true}) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? Image.network(
                    product.imageUrl!,
                    height: 108, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _imagePlaceholder())
                : _imagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (showFarmer && product.farmerName != null)
                Text('by ${product.farmerName}',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.green[600]),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('KSh ${product.price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold, fontSize: 13)),
              if (product.averageRating != null && product.averageRating! > 0)
                Row(children: [
                  ...List.generate(5, (i) => Icon(
                    i < product.averageRating!.floor()
                        ? Icons.star_rounded
                        : (i < product.averageRating!
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded),
                    color: Colors.amber, size: 11,
                  )),
                  const SizedBox(width: 3),
                  Text(product.averageRating!.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: Colors.grey[600])),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────
  Widget _imagePlaceholder() => Container(
    height: 108, color: Colors.green[50],
    child: const Center(child: Icon(Icons.grass, color: Colors.green, size: 36)),
  );

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _heroBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: Text(text,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
  );

  Widget _statCard(String emoji, String title, String subtitle) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(title,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        Text(subtitle,
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[600]),
            textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _reasonTile(String emoji, String title, String subtitle) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey[600])),
          ])),
        ]),
      );
}

// ── Data class ─────────────────────────────────────────────────────────
class _FarmerSummary {
  final String  name;
  final int?    farmerId;
  final double  avgRating;
  final int     ratingCount;
  final String? farmerLocation;
  final String? farmerPhoto;

  const _FarmerSummary({
    required this.name,
    required this.farmerId,
    required this.avgRating,
    required this.ratingCount,
    required this.farmerLocation,
    required this.farmerPhoto,
  });
}