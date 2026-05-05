import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/api_helper.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  FarmerDashboard? stats;
  List<Map<String, dynamic>> myProducts = [];
  List<Map<String, dynamic>> myOrders   = [];

  bool loadingStats    = true;
  bool loadingProducts = true;
  bool loadingOrders   = true;
  String statsError    = '';

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

        // Enrich with item details if missing
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

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  double get _revenue {
    if ((stats?.totalRevenue ?? 0) > 0) return stats!.totalRevenue;
    return myOrders
        .where((o) => o['status'] == 'paid' || o['status'] == 'delivered')
        .fold(0.0, (s, o) =>
            s + (double.tryParse(o['total_price']?.toString() ?? '0') ?? 0));
  }

  int get _pendingCount =>
      stats?.pendingOrders ?? myOrders.where((o) => o['status'] == 'pending').length;
  int get _deliveredCount =>
      stats?.deliveredOrders ?? myOrders.where((o) => o['status'] == 'delivered').length;
  int get _totalOrders => stats?.totalOrders ?? myOrders.length;

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
          tabs: const [Tab(text: 'Overview'), Tab(text: 'My Products'), Tab(text: 'Orders')],
        ),
      ),
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              backgroundColor: Colors.green[700],
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add Product',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: [_overviewTab(), _productsTab(), _ordersTab()],
      ),
    );
  }

  // ── OVERVIEW ─────────────────────────────────────────────────────
  Widget _overviewTab() {
    return RefreshIndicator(
      onRefresh: () async { _loadStats(); _loadOrders(); _loadProducts(); },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Revenue card
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
              Text('Total Revenue', style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              (loadingStats && loadingOrders)
                  ? const SizedBox(height: 44, child: Center(
                      child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)))
                  : Text('KSh ${_fmt(_revenue)}',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _heroStat('Total Orders', '$_totalOrders'),
                _vDiv(),
                _heroStat('Pending', '$_pendingCount', color: Colors.orange[200]!),
                _vDiv(),
                _heroStat('Delivered', '$_deliveredCount', color: Colors.greenAccent),
              ]),
            ]),
          ),

          const SizedBox(height: 16),

          // Stats grid
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _statTile('🛒', 'Products Listed', '${myProducts.length}', Colors.blue),
              _statTile('📦', 'Total Orders',    '$_totalOrders',         Colors.green),
              _statTile('⏳', 'Pending',          '$_pendingCount',        Colors.orange),
              _statTile('✅', 'Delivered',        '$_deliveredCount',      Colors.teal),
            ],
          ),

          const SizedBox(height: 20),

          if (myProducts.isNotEmpty) ...[
            Text('Your Products 🌿', style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...myProducts.take(5).map(_miniProductRow),
          ],

          if (myOrders.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Recent Orders 📋', style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...myOrders.take(3).map(_orderCard),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── PRODUCTS TAB ─────────────────────────────────────────────────
  Widget _productsTab() {
    if (loadingProducts) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (myProducts.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🌿', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        Text('No products yet', style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Tap + to add your first product',
            style: GoogleFonts.poppins(color: Colors.grey[600])),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _showAddProductDialog,
          icon: const Icon(Icons.add),
          label: Text('Add Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myProducts.length,
        itemBuilder: (context, i) => _fullProductRow(myProducts[i]),
      ),
    );
  }

  // ── ORDERS TAB ───────────────────────────────────────────────────
  Widget _ordersTab() {
    if (loadingOrders) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (myOrders.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('No orders yet', style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Customer orders will appear here',
            style: GoogleFonts.poppins(color: Colors.grey[600])),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myOrders.length,
        itemBuilder: (context, i) => _orderCard(myOrders[i]),
      ),
    );
  }

  // ── ORDER CARD with customer + items ──────────────────────────────
  Widget _orderCard(Map<String, dynamic> o) {
    final status     = o['status']?.toString() ?? 'pending';
    final orderId    = o['id'];
    final totalPrice = double.tryParse(o['total_price']?.toString() ?? '0') ?? 0.0;
    final consumer   = o['consumer_name'] ?? o['consumer_username'] ??
                       o['buyer_name'] ?? o['user_name'];
    final phone      = o['consumer_phone'] ?? o['buyer_phone'];
    final address    = o['delivery_address'] ?? o['address'];
    final List items = (o['items'] is List) ? o['items'] as List : [];

    Color sc;
    IconData si;
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
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(si, color: sc, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #$orderId', style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 15)),
              if (o['created_at'] != null)
                Text(_fmtDate(o['created_at'].toString()),
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('KSh ${_fmt(totalPrice)}', style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green[700])),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sc.withOpacity(0.3))),
                child: Text(status, style: GoogleFonts.poppins(
                    fontSize: 10, color: sc, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 10),
        const Divider(height: 1, indent: 16, endIndent: 16),

        // Customer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Customer', style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              CircleAvatar(
                radius: 16, backgroundColor: Colors.blue[50],
                child: Text(
                  consumer != null && consumer.toString().isNotEmpty
                      ? consumer.toString()[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                      color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(consumer?.toString() ?? 'Unknown customer',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                if (phone != null)
                  Text(phone.toString(),
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
              ])),
              if (o['payment_method'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    o['payment_method'] == 'pod' ? '💵 POD' : '📱 M-Pesa',
                    style: GoogleFonts.poppins(fontSize: 10,
                        color: Colors.blue[700], fontWeight: FontWeight.w500),
                  ),
                ),
            ]),
            if (address != null && address.toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.red[400]),
                const SizedBox(width: 4),
                Expanded(child: Text(address.toString(),
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
              ]),
            ],
          ]),
        ),

        // Items
        if (items.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text('Items Ordered', style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          ),
          ...items.map((item) {
            final m    = item as Map<String, dynamic>;
            final name = m['product_name'] ?? m['name'] ?? 'Product #${m['product']}';
            final qty  = m['quantity'] ?? 1;
            final price = double.tryParse(
                m['unit_price']?.toString() ?? m['price']?.toString() ?? '0') ?? 0.0;
            final img  = m['product_image'] ?? m['image'] ?? m['image_url'];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: img != null && img.toString().isNotEmpty
                      ? Image.network(img.toString(), width: 40, height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _itemPlaceholder())
                      : _itemPlaceholder(),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(name.toString(),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('x$qty', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(width: 10),
                Text('KSh ${_fmt(price * qty)}',
                    style: GoogleFonts.poppins(fontSize: 13,
                        fontWeight: FontWeight.bold, color: Colors.green[700])),
              ]),
            );
          }),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('No item details available',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
          ),

        const SizedBox(height: 14),
      ]),
    );
  }

  Widget _itemPlaceholder() => Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Icon(Icons.grass, color: Colors.green, size: 18)));

  // ── PRODUCT ROWS ─────────────────────────────────────────────────
  Widget _miniProductRow(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(children: [
        const Text('🌿', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(p['name']?.toString() ?? '',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13))),
        Text('KSh ${double.tryParse(p['price']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'}',
            style: GoogleFonts.poppins(fontSize: 13,
                color: Colors.green[700], fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _fullProductRow(Map<String, dynamic> p) {
    // Backend uses `quantity` as the stock field
    final qty = p['quantity'] ?? p['stock'];
    final stockVal = qty != null ? int.tryParse(qty.toString()) ?? 0 : 0;
    final name  = p['name']?.toString() ?? 'Product';
    final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
    final id    = p['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: (p['image'] != null && p['image'].toString().isNotEmpty)
              ? Image.network(p['image'].toString(), width: 52, height: 52,
                  fit: BoxFit.cover, errorBuilder: (c, e, s) => _pPlaceholder())
              : _pPlaceholder(),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('KSh ${price.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[700])),
          Row(children: [
            Icon(
              stockVal > 0 ? Icons.inventory_2_outlined : Icons.warning_amber_rounded,
              size: 13,
              color: stockVal > 5 ? Colors.green : (stockVal > 0 ? Colors.orange : Colors.red),
            ),
            const SizedBox(width: 3),
            Text(
              stockVal > 0 ? '$stockVal in stock' : 'Out of stock',
              style: GoogleFonts.poppins(fontSize: 11,
                  color: stockVal > 5 ? Colors.green[600]
                      : (stockVal > 0 ? Colors.orange[700] : Colors.red)),
            ),
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

  Widget _pPlaceholder() => Container(width: 52, height: 52, color: Colors.green[50],
      child: const Center(child: Icon(Icons.grass, color: Colors.green, size: 24)));

  // ── STOCK DIALOG ──────────────────────────────────────────────────
  void _showStockDialog(dynamic id, String name, int current) {
    final ctrl = TextEditingController(text: current.toString());
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Update Stock', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(name, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'New quantity',
              labelStyle: GoogleFonts.poppins(fontSize: 13),
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
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
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
                    ..['stock'] = newVal;
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      )),
    );
  }

  // ── ADD PRODUCT DIALOG ────────────────────────────────────────────
  void _showAddProductDialog() {
    final nameCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final qtyCtrl   = TextEditingController(text: '0');
    final unitCtrl  = TextEditingController();
    // Backend category slugs
    String category = 'vegetables';
    bool saving = false;

    final categories = [
      {'label': 'Vegetables',      'slug': 'vegetables'},
      {'label': 'Fruits',          'slug': 'fruits'},
      {'label': 'Grains',          'slug': 'grains'},
      {'label': 'Animal Products', 'slug': 'animal_products'},
      {'label': 'Manure',          'slug': 'manure'},
      {'label': 'Others',          'slug': 'others'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add New Product',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(nameCtrl,  'Product Name',          Icons.eco_outlined),
          const SizedBox(height: 10),
          _field(priceCtrl, 'Price (KSh)',            Icons.payments_outlined,
              type: TextInputType.number),
          const SizedBox(height: 10),
          _field(qtyCtrl,   'Quantity / Stock',       Icons.inventory_outlined,
              type: TextInputType.number),
          const SizedBox(height: 10),
          _field(unitCtrl,  'Unit (e.g. kg, bunch)',  Icons.straighten_outlined),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: category,
            decoration: InputDecoration(
              labelText: 'Category', labelStyle: GoogleFonts.poppins(fontSize: 13),
              filled: true, fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: categories.map((c) => DropdownMenuItem(
              value: c['slug'], child: Text(c['label']!,
                  style: GoogleFonts.poppins(fontSize: 13)))).toList(),
            onChanged: (v) => setS(() => category = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descCtrl, maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description', labelStyle: GoogleFonts.poppins(fontSize: 13),
              filled: true, fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: saving ? null : () async {
              if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and price are required.')));
                return;
              }
              setS(() => saving = true);
              try {
                await DashboardService.addProduct({
                  'name':        nameCtrl.text.trim(),
                  'price':       priceCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'quantity':    int.tryParse(qtyCtrl.text.trim()) ?? 0,
                  'unit':        unitCtrl.text.trim(),
                  'category':    category,
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Product added! ✅', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.green[700], behavior: SnackBarBehavior.floating,
                ));
                _loadProducts();
              } catch (e) {
                setS(() => saving = false);
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error: $e', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Add', style: GoogleFonts.poppins()),
          ),
        ],
      )),
    );
  }

  TextField _field(TextEditingController c, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c, keyboardType: type,
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.poppins(fontSize: 13),
        filled: true, fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon),
      ),
      style: GoogleFonts.poppins(fontSize: 13),
    );
  }

  Widget _heroStat(String label, String value, {Color color = Colors.white}) {
    return Column(children: [
      Text(value, style: GoogleFonts.poppins(
          color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _vDiv() => Container(height: 40, width: 1, color: Colors.white24);

  Widget _statTile(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
      ]),
    );
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['','Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month]} ${dt.year}';
    } catch (_) { return raw; }
  }
}