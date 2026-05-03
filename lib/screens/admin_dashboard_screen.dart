import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminDashboard? dashboard;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await DashboardService.getAdminDashboard();
      setState(() {
        dashboard = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Could not load dashboard: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text("Admin Dashboard",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _loadDashboard();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigo))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(errorMessage,
                          style: GoogleFonts.poppins(color: Colors.red),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboard,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo[700]!, Colors.indigo[400]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Platform Overview",
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text("County Analytics",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _headerStat("Total Orders",
                                    "${dashboard?.totalOrders ?? 0}"),
                                _vDivider(),
                                _headerStat("Total Revenue",
                                    "KSh ${_fmt(dashboard?.totalRevenue ?? 0)}"),
                                _vDivider(),
                                _headerStat("Active Farmers",
                                    "${dashboard?.activeFarmers ?? 0}"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _statTile("📦", "Pending Orders",
                              "${dashboard?.pendingOrders ?? 0}",
                              Colors.orange),
                          _statTile("✅", "Delivered Orders",
                              "${dashboard?.deliveredOrders ?? 0}",
                              Colors.green),
                          _statTile("👥", "Total Consumers",
                              "${dashboard?.totalConsumers ?? 0}",
                              Colors.blue),
                          _statTile("🛒", "Total Products",
                              "${dashboard?.totalProducts ?? 0}",
                              Colors.purple),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Top products
                      if (dashboard?.topProducts != null &&
                          dashboard!.topProducts!.isNotEmpty) ...[
                        Text("Top Products 🌽",
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ...dashboard!.topProducts!
                            .take(5)
                            .map((p) => _productRow(p)),
                      ],

                      const SizedBox(height: 20),

                      // Recent orders
                      if (dashboard?.recentOrders != null &&
                          dashboard!.recentOrders!.isNotEmpty) ...[
                        Text("Recent Orders 📋",
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ...dashboard!.recentOrders!
                            .take(5)
                            .map((o) => _orderRow(o)),
                      ],

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _vDivider() =>
      Container(height: 40, width: 1, color: Colors.white24);

  Widget _statTile(
      String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _productRow(TopProduct p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Center(child: Text("🌿", style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(p.productName,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${p.totalOrders} orders",
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[600])),
              Text("KSh ${_fmt(p.totalRevenue)}",
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderRow(RecentOrder o) {
    Color statusColor;
    switch (o.status) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'delivered':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order #${o.orderId}",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(o.consumerName ?? "—",
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("KSh ${_fmt(o.totalPrice)}",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green[800])),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(o.status,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double val) {
    if (val >= 1000000) {
      return "${(val / 1000000).toStringAsFixed(1)}M";
    } else if (val >= 1000) {
      return "${(val / 1000).toStringAsFixed(1)}K";
    }
    return val.toStringAsFixed(0);
  }
}