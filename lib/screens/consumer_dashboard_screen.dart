import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/api_helper.dart';
import '../models/order.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';
import 'orders_screen.dart';
import 'submit_rating_screen.dart';   

class ConsumerDashboardScreen extends StatefulWidget {
  const ConsumerDashboardScreen({super.key});

  @override
  State<ConsumerDashboardScreen> createState() =>
      _ConsumerDashboardScreenState();
}

class _ConsumerDashboardScreenState extends State<ConsumerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  List<Order>  _orders     = [];
  List<Rating> _myRatings  = [];
  Map<String, dynamic>? _profile;

  bool _loadingOrders  = true;
  bool _loadingProfile = true;
  bool _loadingRatings = true;
  String _error = '';

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

  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadOrders(), _loadRatings()]);
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final res = await ApiHelper.get('/users/profile/');
      if (res.statusCode == 200) {
        setState(() {
          _profile        = jsonDecode(res.body) as Map<String, dynamic>;
          _loadingProfile = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _loadingProfile = false);
  }

  Future<void> _loadOrders() async {
    setState(() { _loadingOrders = true; _error = ''; });
    try {
      final res = await ApiHelper.get('/orders/');
      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body) as List;
        setState(() {
          _orders        = raw
              .map((o) => Order.fromJson(o as Map<String, dynamic>))
              .toList();
          _loadingOrders = false;
        });
        return;
      }
      setState(() {
        _error         = 'Status ${res.statusCode}';
        _loadingOrders = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loadingOrders = false; });
    }
  }

  Future<void> _loadRatings() async {
    setState(() => _loadingRatings = true);
    try {
      final r = await RatingService.getMyRatings();
      setState(() { _myRatings = r; _loadingRatings = false; });
    } catch (_) {
      setState(() => _loadingRatings = false);
    }
  }

  // ── Navigate to SubmitRatingScreen (fully open — user picks farmer + order)
  Future<void> _goAddReview() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        // FIXED: Removed 'const' here to avoid the assertion error during compilation
        builder: (_) => SubmitRatingScreen(), 
      ),
    );
    if (submitted == true) _loadRatings();
  }

  // ── Derived stats ────────────────────────────────────────────────────
  double get _totalSpent => _orders
      .where((o) => o.status == 'paid' || o.status == 'delivered')
      .fold(0.0, (s, o) => s + o.totalPrice);

  int get _deliveredCount =>
      _orders.where((o) => o.status == 'delivered').length;

  int get _pendingCount => _orders
      .where((o) => o.status == 'pending' || o.status == 'pending_payment')
      .length;

  List<MapEntry<String, int>> get _topProducts {
    final counts = <String, int>{};
    for (final o in _orders) {
      for (final item in o.orderItems) {
        counts[item.productName] =
            (counts[item.productName] ?? 0) + item.quantity;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  List<MapEntry<String, double>> get _topFarmers {
    final spend = <String, double>{};
    for (final o in _orders) {
      final name = _farmerNameFromOrder(o);
      spend[name] = (spend[name] ?? 0) + o.totalPrice;
    }
    final sorted = spend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  String _farmerNameFromOrder(Order o) {
    try {
      final name = (o as dynamic).farmerName as String?;
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return 'Unknown Farmer';
  }

  List<Map<String, dynamic>> get _monthlySpend {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i));
      final total = _orders.where((o) {
        if (o.createdAt.isEmpty) return false;
        try {
          final dt = DateTime.parse(o.createdAt);
          return dt.year == month.year && dt.month == month.month;
        } catch (_) { return false; }
      }).fold(0.0, (s, o) => s + o.totalPrice);
      const m = ['','Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'];
      return {'label': m[month.month], 'amount': total};
    });
  }

  double get _avgStarsGiven => _myRatings.isEmpty
      ? 0.0
      : _myRatings.fold<int>(0, (s, r) => s + r.stars) /
          _myRatings.length;

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text('My Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'My Buys'),
            Tab(text: 'My Reviews'),
          ],
        ),
      ),
      body: (_loadingOrders || _loadingProfile)
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _error.isNotEmpty
              ? _errorView()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _overviewTab(),
                    _myBuysTab(),
                    _myReviewsTab(),
                  ],
                ),
    );
  }

  Widget _errorView() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Could not load dashboard',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_error,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white),
          ),
        ]),
      );

  Widget _overviewTab() {
    final username = _profile?['username']?.toString() ?? 'Consumer';
    final phone    = _profile?['phone_number']?.toString();
    final location =
        (_profile?['profile'] as Map?)?['location']?.toString();

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.teal[700]!, Colors.teal[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.25),
                child: Text(_initials(username),
                    style: GoogleFonts.poppins(
                        fontSize: 22, color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(username,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                if (phone != null)
                  Text(phone,
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 13)),
                if (location != null)
                  Row(children: [
                    const Icon(Icons.location_on,
                        size: 12, color: Colors.white60),
                    const SizedBox(width: 3),
                    Text(location,
                        style: GoogleFonts.poppins(
                            color: Colors.white60, fontSize: 12)),
                  ]),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _statTile('💰', 'Total Spent',
                  'KSh ${_fmt(_totalSpent)}', Colors.teal),
              _statTile('📦', 'Total Orders',
                  '${_orders.length}', Colors.blue),
              _statTile('✅', 'Delivered',
                  '$_deliveredCount', Colors.green),
              _statTile('⭐', 'Reviews Given',
                  '${_myRatings.length}', Colors.amber),
            ],
          ),
          const SizedBox(height: 20),
          if (_orders.isNotEmpty) ...[
            Text('Spending over 6 months',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _spendBarChart(),
            const SizedBox(height: 20),
          ],
          if (_topProducts.isNotEmpty) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text('Most bought products',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => _tabs.animateTo(1),
                child: Text('See all',
                    style: GoogleFonts.poppins(
                        color: Colors.teal[700], fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 8),
            ..._topProducts.take(3).map((e) => _productStatRow(
                e.key, e.value, _topProducts.first.value)),
            const SizedBox(height: 20),
          ],
          if (_topFarmers.isNotEmpty) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text('Favourite farmers',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => _tabs.animateTo(2),
                child: Text('My Reviews',
                    style: GoogleFonts.poppins(
                        color: Colors.teal[700], fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 8),
            ..._topFarmers.take(3).map((e) => _farmerStatRow(
                e.key, e.value, _topFarmers.first.value)),
            const SizedBox(height: 20),
          ],
          Text('Quick actions',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _actionTile(
              icon: Icons.receipt_long_rounded,
              label: 'My Orders',
              color: Colors.blue,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const OrdersScreen())),
            )),
            const SizedBox(width: 12),
            Expanded(child: _actionTile(
              icon: Icons.star_rounded,
              label: 'My Reviews',
              color: Colors.amber,
              onTap: () => _tabs.animateTo(2),
            )),
          ]),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _myBuysTab() {
    if (_topProducts.isEmpty) {
      return _emptyState('🛒', 'No purchases yet',
          'Products you order will appear here');
    }
    final maxQty = _topProducts.first.value;
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryBanner(
            emoji: '🛍️',
            title: '${_orders.length} orders placed',
            subtitle: 'Total KSh ${_fmt(_totalSpent)} spent',
            color: Colors.teal,
          ),
          const SizedBox(height: 20),
          Text('Products you buy most',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._topProducts.map((e) => _productStatRow(
              e.key, e.value, maxQty,
              showRank: true, rank: _topProducts.indexOf(e) + 1)),
          const SizedBox(height: 24),
          Text('Order history by status',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _statusBreakdown(),
          const SizedBox(height: 24),
          Text('Spending trend',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _spendBarChart(),
          const SizedBox(height: 24),
          _infoCard(
            icon: Icons.calculate_outlined,
            label: 'Average order value',
            value: _orders.isEmpty
                ? 'KSh 0'
                : 'KSh ${_fmt(_totalSpent / _orders.length)}',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.local_shipping_outlined,
            label: 'Delivery success rate',
            value: _orders.isEmpty
                ? '0%'
                : '${(_deliveredCount / _orders.length * 100).toStringAsFixed(0)}%',
            color: Colors.green,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _myReviewsTab() {
    if (_loadingRatings) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.teal));
    }

    return RefreshIndicator(
      onRefresh: _loadRatings,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _goAddReview,
              icon: const Icon(Icons.add_comment_rounded),
              label: Text('Add a Review',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_myRatings.isEmpty) ...[
            const SizedBox(height: 40),
            Center(child: Column(children: [
              const Text('📝', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('No reviews yet',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text("You haven't reviewed any farmers yet",
                  style: GoogleFonts.poppins(color: Colors.grey[500]),
                  textAlign: TextAlign.center),
            ])),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.amber[700]!, Colors.orange[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${_myRatings.length}',
                      style: GoogleFonts.poppins(
                          fontSize: 40, fontWeight: FontWeight.bold,
                          color: Colors.white, height: 1)),
                  Text('reviews given',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12)),
                ]),
                const SizedBox(width: 24),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Your avg rating',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12)),
                  Row(children: [
                    ...List.generate(5, (i) => Icon(
                      i < _avgStarsGiven.floor()
                          ? Icons.star_rounded
                          : (i < _avgStarsGiven
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded),
                      color: Colors.white, size: 18,
                    )),
                    const SizedBox(width: 6),
                    Text(_avgStarsGiven.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 4),
                  Text('Thank you for supporting local farmers! 🌱',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 11)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            ..._myRatings.map(_reviewCard),
          ],
        ],
      ),
    );
  }

  Widget _reviewCard(Rating r) {
    final initials = r.farmerName.isNotEmpty
        ? r.farmerName[0].toUpperCase() : '🌾';
    final dateStr = r.createdAt.length >= 10
        ? r.createdAt.substring(0, 10) : r.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.green[100],
              child: Text(initials,
                  style: GoogleFonts.poppins(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(r.farmerName,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              Text('Order #${r.order}  •  $dateStr',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[400])),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${r.stars}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, color: Colors.amber[800])),
                const SizedBox(width: 3),
                Icon(Icons.star_rounded,
                    color: Colors.amber[700], size: 14),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: List.generate(5, (i) => Icon(
            i < r.stars
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: Colors.amber, size: 16,
          ))),
        ),
        if (r.review != null && r.review!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(r.review!,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[700],
                      height: 1.5),
                  maxLines: 4, overflow: TextOverflow.ellipsis),
            ),
          ),
        const SizedBox(height: 14),
      ]),
    );
  }

  Widget _statTile(String emoji, String label, String value,
          MaterialColor color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: color[700]),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey[600])),
        ]),
      );

  Widget _summaryBanner({
    required String emoji,
    required String title,
    required String subtitle,
    required MaterialColor color,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color[700]!, color[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 12)),
          ])),
        ]),
      );

  Widget _productStatRow(String name, int qty, int maxQty,
          {bool showRank = false, int rank = 0}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            if (showRank)
              Container(
                width: 28, height: 28,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                    color: Colors.teal[50], shape: BoxShape.circle),
                child: Center(child: Text('$rank',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.teal[700],
                        fontWeight: FontWeight.bold))),
              ),
            Expanded(child: Text(name,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('$qty unit${qty == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.teal[700],
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: maxQty > 0 ? qty / maxQty : 0,
              backgroundColor: Colors.teal[50],
              color: Colors.teal[400], minHeight: 7,
            ),
          ),
        ]),
      );

  Widget _farmerStatRow(String name, double spend, double maxSpend) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4, offset: const Offset(0, 2))]),
        child: Row(children: [
          CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: Text(_initials(name),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.green[800],
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(name,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: maxSpend > 0 ? spend / maxSpend : 0,
                backgroundColor: Colors.green[50],
                color: Colors.green[400], minHeight: 5,
              ),
            ),
          ])),
          const SizedBox(width: 10),
          Text('KSh ${_fmt(spend)}',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.green[700],
                  fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _spendBarChart() {
    final monthly = _monthlySpend;
    final maxAmt  = monthly.fold<double>(0,
        (m, e) =>
            (e['amount'] as double) > m ? (e['amount'] as double) : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: monthly.map((m) {
            final amt   = (m['amount'] as double);
            final ratio = maxAmt > 0 ? amt / maxAmt : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                  if (amt > 0)
                    Text(_fmt(amt),
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.teal[700]),
                        textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Container(
                    height: ratio * 80 + 2,
                    decoration: BoxDecoration(
                      color: ratio == 1.0 ? Colors.teal[700] : Colors.teal[200],
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(m['label'].toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey[600])),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _statusBreakdown() {
    final statuses = ['pending', 'paid', 'shipped', 'delivered', 'cancelled'];
    return Column(children: statuses.map((s) {
      final count = _orders.where((o) => o.status == s).length;
      if (count == 0) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _infoCard(
          icon: s == 'delivered' ? Icons.check_circle_outline : Icons.info_outline,
          label: s.toUpperCase(),
          value: '$count',
          color: s == 'delivered' ? Colors.green : Colors.blueGrey,
        ),
      );
    }).toList());
  }

  Widget _infoCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
        const Spacer(),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }

  Widget _actionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _emptyState(String emoji, String title, String sub) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 50)),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(sub, style: GoogleFonts.poppins(color: Colors.grey)),
        ]),
      );
}