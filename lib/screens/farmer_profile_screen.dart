import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/farmer_service.dart';
import '../services/rating_service.dart';
import '../models/rating.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'ratings_screen.dart';
import 'submit_rating_screen.dart';
import '../widgets/farmer_avatar.dart';

class FarmerProfileScreen extends StatefulWidget {
  final int     farmerId;
  final String  farmerName;
  final String? farmerLocation;

  const FarmerProfileScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    this.farmerLocation,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  FarmerProfile?       _profile;
  FarmerRatingSummary? _ratings;
  List<Product>        _products = [];
  bool _loadingProfile  = true;
  bool _loadingRatings  = true;
  bool _loadingProducts = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadRatings(), _loadProducts()]);
  }

  Future<void> _loadProfile() async {
    try {
      final p = await FarmerService.getFarmerProfile(widget.farmerId);
      if (mounted) setState(() { _profile = p; _loadingProfile = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadRatings() async {
    try {
      final r = await RatingService.getFarmerRatingById(widget.farmerId);
      if (mounted) setState(() { _ratings = r; _loadingRatings = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRatings = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final all = await ProductService.getProducts();
      final mine = all.where((p) => p.farmerId == widget.farmerId).toList();
      if (mounted) setState(() { _products = mine; _loadingProducts = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  String get _displayName => _profile?.username ?? widget.farmerName;
  String get _location =>
      _profile?.location ?? widget.farmerLocation ?? 'Nairobi, Kenya';
  String? get _photoUrl => _profile?.profilePhoto;

  @override
  Widget build(BuildContext context) {
    final avgRating    = _ratings?.averageRating ?? 0.0;
    final totalReviews = _ratings?.totalRatings ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final submitted = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmitRatingScreen(
                      preselectedFarmerId:   widget.farmerId,
                      preselectedFarmerName: _displayName,
                    ),
                  ),
                );
                if (submitted == true) _loadRatings();
              },
              icon: const Icon(Icons.rate_review_rounded),
              label: Text('Rate this Farmer',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Hero header ───────────────────────────────────────
          SliverAppBar(
            // Increased from 300 → 360 to give the TabBar room below the stars
            expandedHeight: 360,
            pinned: true,
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _loadingProfile  = true;
                    _loadingRatings  = true;
                    _loadingProducts = true;
                  });
                  _loadAll();
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green[900]!, Colors.teal[600]!],
                    ),
                  ),
                ),
                Positioned(top: -40, right: -40,
                    child: _circle(180, Colors.white.withOpacity(0.05))),
                Positioned(bottom: -20, left: -30,
                    child: _circle(140, Colors.white.withOpacity(0.05))),
                // ── Content — extra bottom padding keeps it above the TabBar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile photo
                      _loadingProfile
                          ? CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : _photoUrl != null && _photoUrl!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 44,
                                  backgroundImage: NetworkImage(_photoUrl!),
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  onBackgroundImageError: (_, _) {})
                              : CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: Text(
                                    _displayName.isNotEmpty
                                        ? _displayName[0].toUpperCase()
                                        : '🌾',
                                    style: GoogleFonts.poppins(
                                        fontSize: 36, color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  )),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Flexible(
                          child: Text(_displayName,
                              style: GoogleFonts.poppins(
                                  fontSize: 22, fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                      ]),
                      const SizedBox(height: 4),
                      Text('📍 $_location',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                      if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_profile!.bio!,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.white60,
                                fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 10),
                      // Stars row
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ...List.generate(5, (i) => Icon(
                          i < avgRating.floor()
                              ? Icons.star_rounded
                              : (i < avgRating
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded),
                          color: Colors.amber, size: 20,
                        )),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            totalReviews == 0
                                ? 'No reviews yet'
                                : '${avgRating.toStringAsFixed(1)} ($totalReviews reviews)',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.greenAccent,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.store_outlined), text: 'Products'),
                Tab(icon: Icon(Icons.star_outline_rounded), text: 'Reviews'),
              ],
            ),
          ),

          // ── Stats strip ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                _statChip('🥬', '${_products.length}', 'Products'),
                const SizedBox(width: 10),
                _statChip('⭐', avgRating.toStringAsFixed(1), 'Avg Rating'),
                const SizedBox(width: 10),
                _statChip('💬', '$totalReviews', 'Reviews'),
                if (_profile?.farmSize != null) ...[
                  const SizedBox(width: 10),
                  _statChip('🌾', '${_profile!.farmSize!.toStringAsFixed(1)}ac', 'Farm'),
                ],
              ]),
            ),
          ),

          // ── Tab content ───────────────────────────────────────
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabs,
              children: [_productsTab(), _reviewsTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Products tab ────────────────────────────────────────────────
  Widget _productsTab() {
    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (_products.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🥬', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No products listed yet',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) => _productCard(_products[i]),
    );
  }

  Widget _productCard(Product p) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                ? Image.network(p.imageUrl!, height: 110, width: double.infinity,
                    fit: BoxFit.cover, errorBuilder: (c, e, s) => _imgPlaceholder())
                : _imgPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('KSh ${p.price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 13)),
              if (p.averageRating != null && p.averageRating! > 0)
                Row(children: [
                  Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                  const SizedBox(width: 3),
                  Text(p.averageRating!.toStringAsFixed(1),
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    height: 110, color: Colors.green[50],
    child: const Center(child: Icon(Icons.grass, color: Colors.green, size: 32)));

  // ── Reviews tab ─────────────────────────────────────────────────
  Widget _reviewsTab() {
    if (_loadingRatings) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    final ratings = _ratings?.ratings ?? [];
    if (ratings.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('⭐', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No reviews yet',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        Text('Be the first to review!',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: ratings.length,
      itemBuilder: (_, i) => _reviewCard(ratings[i]),
    );
  }

  Widget _reviewCard(Rating r) {
    final initials = r.consumerName.isNotEmpty ? r.consumerName[0].toUpperCase() : '?';
    final dateStr  = r.createdAt.length >= 10 ? r.createdAt.substring(0, 10) : r.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20, backgroundColor: Colors.teal[100],
            child: Text(initials, style: GoogleFonts.poppins(
                color: Colors.teal[800], fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.consumerName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(dateStr,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400])),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${r.stars}', style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber[800])),
              const SizedBox(width: 3),
              Icon(Icons.star_rounded, color: Colors.amber[700], size: 14),
            ]),
          ),
        ]),
        if (r.review != null && r.review!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(r.review!, style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.grey[700], height: 1.5)),
        ],
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
  Widget _statChip(String emoji, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[800])),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500]),
            textAlign: TextAlign.center),
      ]),
    ));

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}