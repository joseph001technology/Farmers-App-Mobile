// lib/screens/farmer_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() =>
      _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  FarmerDashboard? dashboard;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final data = await DashboardService.getFarmerDashboard();
      setState(() {
        dashboard = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Could not load dashboard: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text('My Dashboard',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: _load,
          )
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green))
          : errorMessage.isNotEmpty
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: Colors.green,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(),
                        const SizedBox(height: 16),
                        _buildRevenueCard(),
                        const SizedBox(height: 16),
                        _buildOrderStatsRow(),
                        const SizedBox(height: 16),
                        _buildRatingCard(),
                        const SizedBox(height: 16),
                        _buildTopProducts(),
                        const SizedBox(height: 16),
                        _buildWeeklyRevenue(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          Text(errorMessage,
              style: GoogleFonts.poppins(color: Colors.red),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final name = AuthService.username ?? 'Farmer';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[800]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👋 Hello, $name',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Here\'s how your farm is performing',
              style:
                  GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _headerStat('Products', '${dashboard!.totalProductsListed}'),
              const SizedBox(width: 24),
              _headerStat('Total Orders', '${dashboard!.totalOrders}'),
              const SizedBox(width: 24),
              _headerStat(
                  'Rating', '${dashboard!.averageRating} ⭐'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildRevenueCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: Colors.green, size: 22),
              const SizedBox(width: 8),
              Text('Total Revenue',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'KSh ${dashboard!.totalRevenue.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green[800]),
          ),
          Text('From paid & delivered orders',
              style: GoogleFonts.poppins(
                  color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOrderStatsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Breakdown',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _statTile('Pending',
                    '${dashboard!.pendingOrders}', Colors.orange)),
            const SizedBox(width: 10),
            Expanded(
                child: _statTile(
                    'Paid', '${dashboard!.paidOrders}', Colors.green)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _statTile('Delivered',
                    '${dashboard!.deliveredOrders}', Colors.blue)),
            const SizedBox(width: 10),
            Expanded(
                child: _statTile('Cancelled',
                    '${dashboard!.cancelledOrders}', Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style:
                  GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    final stars = dashboard!.averageRating;
    return _card(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Farmer Rating',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Based on ${dashboard!.totalRatings} reviews',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text('$stars / 5',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700])),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    if (dashboard!.topProducts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🏆 Top Products',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...dashboard!.topProducts.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? Colors.amber[100]
                        : i == 1
                            ? Colors.grey[200]
                            : Colors.brown[50],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: i == 0
                                ? Colors.amber[800]
                                : Colors.grey[700])),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${p.quantitySold} units sold',
                          style: GoogleFonts.poppins(
                              color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text('KSh ${p.revenue.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeeklyRevenue() {
    if (dashboard!.revenueLast7Days.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxRevenue = dashboard!.revenueLast7Days
        .map((d) => d.revenue)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📈 Revenue — Last 7 Days',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        _card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dashboard!.revenueLast7Days.map((d) {
              final height = maxRevenue > 0
                  ? (d.revenue / maxRevenue) * 80
                  : 10.0;
              final label = d.date.length >= 10
                  ? d.date.substring(5) // MM-DD
                  : d.date;
              return Expanded(
                child: Column(
                  children: [
                    Text('KSh${d.revenue.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 8, color: Colors.grey[600]),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Container(
                      height: height.clamp(8.0, 80.0),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: Colors.grey[600]),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}