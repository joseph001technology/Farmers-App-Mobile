import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/api_helper.dart';
import '../services/dashboard_service.dart';
import '../services/rating_service.dart';
import '../models/dashboard.dart';
import '../models/rating.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  FarmerDashboard?            stats;
  List<Map<String, dynamic>>  myProducts = [];
  List<Map<String, dynamic>>  myOrders   = [];
  FarmerRatingSummary?        myRatings;

  bool loadingStats    = true;
  bool loadingProducts = true;
  bool loadingOrders   = true;
  bool loadingRatings  = true;
  String statsError    = '';

  static const _categories = [
    {'label': 'Fresh Produce',          'slug': 'fresh_produce'},
    {'label': 'Grains & Seeds',         'slug': 'grains_seeds'},
    {'label': 'Livestock & Poultry',    'slug': 'livestock'},
    {'label': 'Animal Derivatives',     'slug': 'animal_derivatives'},
    {'label': 'Value-Added Goods',      'slug': 'processed_goods'},
    {'label': 'Nursery & Floral',       'slug': 'nursery_floral'},
    {'label': 'Inputs & Amendments',    'slug': 'inputs_chemicals'},
    {'label': 'Feed & Nutrition',       'slug': 'animal_feed'},
    {'label': 'Heavy Machinery',        'slug': 'machinery'},
    {'label': 'Tools & Hardware',       'slug': 'tools_hardware'},
    {'label': 'Timber & Bio-Resources', 'slug': 'timber_bio'},
    {'label': 'Farm Services',          'slug': 'services'},
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _loadAll() {
    _loadStats();
    _loadProducts();
    _loadOrders();
    _loadRatings();
  }

  Future<void> _loadStats() async {
    setState(() { loadingStats = true; statsError = ''; });
    try {
      final s = await DashboardService.getFarmerDashboard();
      setState(() { stats = s; loadingStats = false; });
    } catch (e) {
      setState(() { statsError = e.toString(); loadingStats = false; });
    }
  }

  Future<void> _loadProducts() async {
    setState(() => loadingProducts = true);
    final p = await DashboardService.getMyProducts();
    setState(() { myProducts = p; loadingProducts = false; });
  }

  Future<void> _loadOrders() async {
    setState(() => loadingOrders = true);
    try {
      final res = await ApiHelper.get('/orders/');
      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body) as List;
        final orders = raw.cast<Map<String, dynamic>>();
        final enriched = <Map<String, dynamic>>[];
        for (final o in orders) {
          final items = o['items'];
          if (items == null || (items is List && items.isEmpty)) {
            try {
              final det = await ApiHelper.get('/orders/${o['id']}/');
              if (det.statusCode == 200) {
                enriched.add(jsonDecode(det.body) as Map<String, dynamic>);
                continue;
              }
            } catch (_) {}
          }
          enriched.add(o);
        }
        setState(() { myOrders = enriched; loadingOrders = false; });
      } else {
        setState(() => loadingOrders = false);
      }
    } catch (_) {
      setState(() => loadingOrders = false);
    }
  }

  Future<void> _loadRatings() async {
    setState(() => loadingRatings = true);
    try {
      // We need the farmer's own ID — get it from profile
      final profileRes = await ApiHelper.get('/users/profile/');
      if (profileRes.statusCode == 200) {
        final profile = jsonDecode(profileRes.body) as Map<String, dynamic>;
        final farmerId = (profile['id'] as num?)?.toInt();
        if (farmerId != null) {
          final summary = await RatingService.getFarmerRatingById(farmerId);
          setState(() { myRatings = summary; loadingRatings = false; });
          return;
        }
      }
    } catch (_) {}
    setState(() => loadingRatings = false);
  }

  // ── Revenue / count helpers ─────────────────────────────────────────
  String _fmt(double v) {
    if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
    if (v >= 1_000)     return '${(v / 1_000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  double get _revenue {
    if ((stats?.totalRevenue ?? 0) > 0) return stats!.totalRevenue;
    return myOrders
        .where((o) => o['status'] == 'paid' || o['status'] == 'delivered')
        .fold(0.0, (s, o) =>
            s + (double.tryParse(o['total_price']?.toString() ?? '0') ?? 0));
  }

  int get _pendingCount   => stats?.pendingOrders   ?? myOrders.where((o) => o['status'] == 'pending').length;
  int get _deliveredCount => stats?.deliveredOrders ?? myOrders.where((o) => o['status'] == 'delivered').length;
  int get _totalOrders    => stats?.totalOrders     ?? myOrders.length;

  // ── Monthly order counts (last 6 months) ───────────────────────────
  List<Map<String, dynamic>> get _monthlyOrders {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i));
      final count = myOrders.where((o) {
        final raw = o['created_at']?.toString() ?? '';
        if (raw.isEmpty) return false;
        try {
          final dt = DateTime.parse(raw);
          return dt.year == month.year && dt.month == month.month;
        } catch (_) { return false; }
      }).length;
      const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return {'label': m[month.month], 'count': count};
    });
  }

  // ── Most consistent customers ───────────────────────────────────────
  List<MapEntry<String, int>> get _topCustomers {
    final counts = <String, int>{};
    for (final o in myOrders) {
      final info = _customerInfo(o);
      final name = info['name'] ?? 'Unknown';
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  // ── Helpers ─────────────────────────────────────────────────────────
  String? _productImageUrl(Map<String, dynamic> p) {
    final url = p['image_url']?.toString();
    if (url != null && url.isNotEmpty) return url;
    final img = p['image']?.toString();
    if (img != null && img.isNotEmpty) return img;
    return null;
  }

  String? _itemImageUrl(Map<String, dynamic> m) {
    for (final key in ['product_image', 'image_url', 'image']) {
      final v = m[key]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  String _categoryLabel(String? slug) {
    if (slug == null) return '';
    return _categories.firstWhere(
      (c) => c['slug'] == slug, orElse: () => {'label': slug})['label']!;
  }

  Map<String, String?> _customerInfo(Map<String, dynamic> o) {
    String? name, phone, location, initials;
    for (final key in ['consumer', 'user', 'buyer']) {
      final raw = o[key];
      if (raw is Map) {
        name  = raw['username']?.toString();
        phone = raw['phone_number']?.toString();
        final profile = raw['profile'];
        if (profile is Map) location = profile['location']?.toString();
        break;
      }
    }
    name     ??= o['consumer_name']?.toString() ?? o['buyer_name']?.toString();
    phone    ??= o['consumer_phone']?.toString();
    location ??= o['delivery_address']?.toString() ?? o['address']?.toString();
    initials   = (name != null && name.isNotEmpty) ? name[0].toUpperCase() : '?';
    return {'name': name, 'phone': phone, 'location': location, 'initials': initials};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text('My Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll)],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Products'), Tab(text: 'Orders')],
        ),
      ),
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              backgroundColor: Colors.green[700],
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add Product',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: [_overviewTab(), _productsTab(), _ordersTab()],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // OVERVIEW TAB — analytics-rich
  // ══════════════════════════════════════════════════════════════════
  Widget _overviewTab() => RefreshIndicator(
    onRefresh: () async { _loadStats(); _loadOrders(); _loadProducts(); _loadRatings(); },
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Revenue hero ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.green[800]!, Colors.green[500]!],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Revenue',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            (loadingStats && loadingOrders)
                ? const SizedBox(height: 44, child: Center(
                    child: CircularProgressIndicator(
                        color: Colors.white54, strokeWidth: 2)))
                : Text('KSh ${_fmt(_revenue)}',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 36,
                        fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _heroStat('Orders', '$_totalOrders'),
              _vDiv(),
              _heroStat('Pending', '$_pendingCount', color: Colors.orange[200]!),
              _vDiv(),
              _heroStat('Delivered', '$_deliveredCount', color: Colors.greenAccent),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // ── 4 stat tiles ──────────────────────────────────────────
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _statTile('🛒', 'Products', '${myProducts.length}', Colors.blue),
            _statTile('📦', 'Orders',    '$_totalOrders',       Colors.green),
            _statTile('⏳', 'Pending',   '$_pendingCount',      Colors.orange),
            _statTile('⭐', 'Avg Rating',
                myRatings == null ? '—'
                    : myRatings!.totalRatings == 0 ? 'No ratings'
                    : '${myRatings!.averageRating.toStringAsFixed(1)}/5',
                Colors.amber),
          ],
        ),

        const SizedBox(height: 20),

        // ── Monthly orders bar chart ──────────────────────────────
        Text('Monthly Orders 📊',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _monthlyOrdersChart(),

        const SizedBox(height: 20),

        // ── Customer rating summary ───────────────────────────────
        Text('How Customers Rate You 🌟',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _ratingAnalyticsCard(),

        const SizedBox(height: 20),

        // ── Most consistent customers ─────────────────────────────
        if (myOrders.isNotEmpty) ...[
          Text('Most Consistent Customers 🤝',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Customers who order from you most',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 10),
          _consistentCustomersCard(),
          const SizedBox(height: 20),
        ],

        // ── Recent ratings from customers ─────────────────────────
        if (myRatings != null && myRatings!.ratings.isNotEmpty) ...[
          Text('Recent Customer Reviews 💬',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...myRatings!.ratings.take(3).map(_miniRatingCard),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 30),
      ],
    ),
  );

  // ── Monthly orders bar chart ────────────────────────────────────────
  Widget _monthlyOrdersChart() {
    final monthly = _monthlyOrders;
    final maxCount = monthly.fold<int>(0, (m, e) =>
        (e['count'] as int) > m ? (e['count'] as int) : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: monthly.map((m) {
            final count = (m['count'] as int);
            final ratio = maxCount > 0 ? count / maxCount : 0.0;
            final isMax = count == maxCount && count > 0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  if (count > 0)
                    Text('$count',
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: Colors.green[700]),
                        textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 80 * ratio + 4,
                    decoration: BoxDecoration(
                      color: isMax ? Colors.green[700] : Colors.green[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(m['label'] as String,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey[500])),
                ]),
              ),
            );
          }).toList(),
        ),
        if (maxCount == 0) ...[
          const SizedBox(height: 8),
          Center(child: Text('No orders yet',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[400]))),
        ],
      ]),
    );
  }

  // ── Rating analytics card ───────────────────────────────────────────
  Widget _ratingAnalyticsCard() {
    if (loadingRatings) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: Colors.green),
          ));
    }
    if (myRatings == null || myRatings!.totalRatings == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          const Text('⭐', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text('No ratings yet',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Text('Deliver great orders and earn your first review!',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center),
        ]),
      );
    }

    final r      = myRatings!;
    final fives  = r.ratings.where((x) => x.stars == 5).length;
    final fours  = r.ratings.where((x) => x.stars == 4).length;
    final threes = r.ratings.where((x) => x.stars == 3).length;
    final below  = r.ratings.where((x) => x.stars < 3).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.amber[700]!, Colors.orange[500]!],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.averageRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                  fontSize: 48, fontWeight: FontWeight.bold,
                  color: Colors.white, height: 1)),
          Row(children: List.generate(5, (i) => Icon(
            i < r.averageRating.floor()
                ? Icons.star_rounded
                : (i < r.averageRating
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            color: Colors.white, size: 16,
          ))),
          const SizedBox(height: 4),
          Text('${r.totalRatings} review${r.totalRatings == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        ]),
        const Spacer(),
        Column(children: [
          _ratingBar('⭐⭐⭐⭐⭐', fives,  r.totalRatings),
          _ratingBar('⭐⭐⭐⭐',  fours,  r.totalRatings),
          _ratingBar('⭐⭐⭐',   threes, r.totalRatings),
          _ratingBar('⭐⭐ & ⭐', below,  r.totalRatings),
        ]),
      ]),
    );
  }

  Widget _ratingBar(String label, int count, int total) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 68,
          child: Text(label,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10))),
      const SizedBox(width: 4),
      SizedBox(
        width: 70, height: 7,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text('$count',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
    ]),
  );

  // ── Most consistent customers card ──────────────────────────────────
  Widget _consistentCustomersCard() {
    final customers = _topCustomers;
    if (customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Center(child: Text('No customer data yet',
            style: GoogleFonts.poppins(color: Colors.grey[400]))),
      );
    }
    final maxOrders = customers.first.value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: customers.asMap().entries.map((entry) {
        final rank   = entry.key + 1;
        final name   = entry.value.key;
        final orders = entry.value.value;
        final ratio  = maxOrders > 0 ? orders / maxOrders : 0.0;
        final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            // Rank
            SizedBox(width: 28,
                child: Center(child: Text(
                  medal ?? '#$rank',
                  style: TextStyle(fontSize: medal != null ? 18 : 12),
                ))),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18, backgroundColor: Colors.blue[100],
              child: Text(initials,
                  style: GoogleFonts.poppins(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.blue[50],
                  color: Colors.blue[400], minHeight: 6,
                ),
              ),
            ])),
            const SizedBox(width: 10),
            Text('$orders order${orders == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.blue[700],
                    fontWeight: FontWeight.bold)),
          ]),
        );
      }).toList()),
    );
  }

  Widget _miniRatingCard(Rating r) {
    final initials = r.consumerName.isNotEmpty
        ? r.consumerName[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16, backgroundColor: Colors.green[100],
          child: Text(initials,
              style: GoogleFonts.poppins(
                  color: Colors.green[800], fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.consumerName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
          if (r.review != null && r.review!.isNotEmpty)
            Text(r.review!,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Row(children: List.generate(5, (i) => Icon(
          i < r.stars ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber, size: 13,
        ))),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PRODUCTS TAB — shows only this farmer's products
  // ══════════════════════════════════════════════════════════════════
  Widget _productsTab() {
    if (loadingProducts) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (myProducts.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🌿', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        Text('No products yet',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Tap + to add your first product',
            style: GoogleFonts.poppins(color: Colors.grey[600])),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _showAddProductDialog,
          icon: const Icon(Icons.add),
          label: Text('Add Product',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header summary
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.teal[500]!]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Text('🌿', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your Products',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text('${myProducts.length} product${myProducts.length == 1 ? '' : 's'} listed',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),
          ...myProducts.map(_fullProductRow),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ORDERS TAB
  // ══════════════════════════════════════════════════════════════════
  Widget _ordersTab() {
    if (loadingOrders) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (myOrders.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('No orders yet',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Customer orders will appear here',
            style: GoogleFonts.poppins(color: Colors.grey[600])),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myOrders.length,
        itemBuilder: (_, i) => _orderCard(myOrders[i]),
      ),
    );
  }

  // ── Order card ─────────────────────────────────────────────────────
  Widget _orderCard(Map<String, dynamic> o) {
    final status     = o['status']?.toString() ?? 'pending';
    final orderId    = o['id'];
    final totalPrice = double.tryParse(o['total_price']?.toString() ?? '0') ?? 0.0;
    final customer   = _customerInfo(o);
    final List items = (o['items'] is List) ? o['items'] as List : [];

    Color sc; IconData si;
    switch (status) {
      case 'paid':      sc = Colors.green;  si = Icons.check_circle_rounded; break;
      case 'delivered': sc = Colors.blue;   si = Icons.local_shipping_rounded; break;
      default:          sc = Colors.orange; si = Icons.access_time_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(si, color: sc, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #$orderId',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              if (o['created_at'] != null)
                Text(_fmtDate(o['created_at'].toString()),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[500])),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('KSh ${_fmt(totalPrice)}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 15,
                      color: Colors.green[700])),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sc.withOpacity(0.3))),
                child: Text(status,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: sc, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 10),
        const Divider(height: 1, indent: 16, endIndent: 16),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            CircleAvatar(
              radius: 16, backgroundColor: Colors.blue[50],
              child: Text(customer['initials'] ?? '?',
                  style: GoogleFonts.poppins(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(customer['name'] ?? 'Unknown',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13))),
            if (items.isNotEmpty)
              Text('${items.length} item${items.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[500])),
          ]),
        ),
      ]),
    );
  }

  // ── Product rows ────────────────────────────────────────────────────
  Widget _fullProductRow(Map<String, dynamic> p) {
    final qty      = p['quantity'] ?? p['stock'];
    final stockVal = qty != null ? int.tryParse(qty.toString()) ?? 0 : 0;
    final name     = p['name']?.toString() ?? 'Product';
    final price    = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
    final id       = p['id'];
    final img      = _productImageUrl(p);
    final catLabel = _categoryLabel(p['category']?.toString());
    final Color stockColor = stockVal > 5 ? Colors.green
        : (stockVal > 0 ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: img != null && img.isNotEmpty
              ? Image.network(img, width: 52, height: 52,
                  fit: BoxFit.cover, errorBuilder: (c, e, s) => _pPh())
              : _pPh(),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('KSh ${price.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.green[700])),
          if (catLabel.isNotEmpty)
            Text(catLabel,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.blueGrey[400]),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(children: [
            Icon(stockVal > 0
                ? Icons.inventory_2_outlined
                : Icons.warning_amber_rounded,
                size: 13, color: stockColor),
            const SizedBox(width: 3),
            Text(stockVal > 0 ? '$stockVal in stock' : 'Out of stock',
                style: GoogleFonts.poppins(fontSize: 11, color: stockColor)),
          ]),
        ])),
        if (id != null)
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.green[700], size: 20),
            tooltip: 'Update Stock',
            onPressed: () => _showStockDialog(id, name, stockVal),
          ),
      ]),
    );
  }

  // ── Stock dialog ────────────────────────────────────────────────────
  void _showStockDialog(dynamic id, String name, int current) {
    final ctrl = TextEditingController(text: current.toString());
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Update Stock',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(name,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'New quantity',
              labelStyle: GoogleFonts.poppins(fontSize: 12),
              filled: true, fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.inventory_2_outlined),
            ),
            style: GoogleFonts.poppins(fontSize: 15),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: saving ? null : () async {
              final newVal = int.tryParse(ctrl.text.trim());
              if (newVal == null || newVal < 0) return;
              setS(() => saving = true);
              final productId = id is int ? id : int.tryParse(id.toString()) ?? 0;
              final ok = await DashboardService.updateStock(productId, newVal);
              setS(() => saving = false);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'Stock updated to $newVal ✅'
                    : 'Saved locally (server may not have updated)'),
                backgroundColor: ok ? Colors.green[700] : Colors.orange[700],
                behavior: SnackBarBehavior.floating,
              ));
              setState(() {
                final idx = myProducts.indexWhere((p) => p['id'] == id);
                if (idx >= 0) {
                  myProducts[idx] = Map.from(myProducts[idx])
                    ..['quantity'] = newVal
                    ..['stock']    = newVal;
                }
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      )),
    );
  }

  // ── Add Product dialog ──────────────────────────────────────────────
  void _showAddProductDialog() {
    final nameCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final qtyCtrl   = TextEditingController(text: '0');
    final unitCtrl  = TextEditingController();
    String category = _categories.first['slug']!;
    bool   saving   = false;
    File?  imageFile;
    final  picker   = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        Future<void> pickImage(ImageSource source) async {
          try {
            final picked = await picker.pickImage(
                source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
            if (picked != null) setS(() => imageFile = File(picked.path));
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not pick image: $e'),
                    backgroundColor: Colors.red[700]));
            }
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Add New Product',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, children: [
            // Image picker
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: ctx,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
                builder: (sheet) => SafeArea(child: Column(
                    mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: Text('Take a photo', style: GoogleFonts.poppins()),
                    onTap: () { Navigator.pop(sheet); pickImage(ImageSource.camera); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: Text('Choose from gallery', style: GoogleFonts.poppins()),
                    onTap: () { Navigator.pop(sheet); pickImage(ImageSource.gallery); },
                  ),
                ])),
              ),
              child: Container(
                width: double.infinity, height: 130,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: imageFile != null ? Colors.green[400]! : Colors.grey[300]!,
                    width: imageFile != null ? 2 : 1,
                  ),
                ),
                child: imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(imageFile!, fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 36, color: Colors.grey[400]),
                        const SizedBox(height: 6),
                        Text('Tap to add product image',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[500])),
                      ]),
              ),
            ),
            const SizedBox(height: 12),
            _field(nameCtrl, 'Product Name', Icons.eco_outlined),
            const SizedBox(height: 8),
            _field(priceCtrl, 'Price (KSh)', Icons.payments_outlined,
                type: TextInputType.number),
            const SizedBox(height: 8),
            _field(qtyCtrl, 'Quantity / Stock', Icons.inventory_outlined,
                type: TextInputType.number),
            const SizedBox(height: 8),
            _field(unitCtrl, 'Unit (e.g. kg, bunch)', Icons.straighten_outlined),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: category,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                filled: true, fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: _categories.map((c) => DropdownMenuItem(
                value: c['slug'],
                child: Text(c['label']!, style: GoogleFonts.poppins(fontSize: 13)),
              )).toList(),
              onChanged: (v) => setS(() => category = v!),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl, maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                filled: true, fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey))),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name and price are required.')));
                  return;
                }
                setS(() => saving = true);
                try {
                  await DashboardService.addProduct(
                    {
                      'name':        nameCtrl.text.trim(),
                      'price':       priceCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'quantity':    int.tryParse(qtyCtrl.text.trim()) ?? 0,
                      'unit':        unitCtrl.text.trim(),
                      'category':    category,
                    },
                    imageFile: imageFile,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Product added! ✅', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.green[700],
                    behavior: SnackBarBehavior.floating,
                  ));
                  _loadProducts();
                } catch (e) {
                  setS(() => saving = false);
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Add', style: GoogleFonts.poppins()),
            ),
          ],
        );
      }),
    );
  }

  // ── UI helpers ──────────────────────────────────────────────────────
  TextField _field(TextEditingController c, String label, IconData icon,
      {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: c, keyboardType: type,
        decoration: InputDecoration(
          labelText: label, labelStyle: GoogleFonts.poppins(fontSize: 13),
          filled: true, fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: Icon(icon),
        ),
        style: GoogleFonts.poppins(fontSize: 13),
      );

  Widget _heroStat(String label, String value,
          {Color color = Colors.white}) =>
      Column(children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center),
      ]);

  Widget _vDiv() =>
      Container(height: 40, width: 1, color: Colors.white24);

  Widget _statTile(String emoji, String label, String value, MaterialColor color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color[700]),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
        ]),
      );

  Widget _pPh() => Container(width: 52, height: 52, color: Colors.green[50],
      child: const Center(child: Icon(Icons.grass, color: Colors.green, size: 24)));

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['','Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month]} ${dt.year}';
    } catch (_) { return raw; }
  }
}