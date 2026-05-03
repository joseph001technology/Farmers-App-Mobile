import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard.dart';

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
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
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
        errorMessage = "Could not load dashboard: $e";
        isLoading = false;
      });
    }
  }

  String _fmt(double val) {
    if (val >= 1000000) return "${(val / 1000000).toStringAsFixed(1)}M";
    if (val >= 1000) return "${(val / 1000).toStringAsFixed(1)}K";
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text("My Dashboard",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green))
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
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white),
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
                      // Revenue hero card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[800]!,
                              Colors.green[500]!
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Revenue",
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              "KSh ${_fmt(dashboard?.totalRevenue ?? 0)}",
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _heroStat("Total Orders",
                                    "${dashboard?.totalOrders ?? 0}"),
                                _vDivider(),
                                _heroStat("Pending",
                                    "${dashboard?.pendingOrders ?? 0}",
                                    color: Colors.orange[200]!),
                                _vDivider(),
                                _heroStat("Delivered",
                                    "${dashboard?.deliveredOrders ?? 0}",
                                    color: Colors.greenAccent),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Top products section
                      if (dashboard?.topProducts != null &&
                          dashboard!.topProducts!.isNotEmpty) ...[
                        Text("Top Products 🌽",
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...List.generate(
                          dashboard!.topProducts!.length > 5
                              ? 5
                              : dashboard!.topProducts!.length,
                          (i) {
                            final p = dashboard!.topProducts![i];
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
                              child: Row(
                                children: [
                                  // Rank badge
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: i == 0
                                          ? Colors.amber[100]
                                          : Colors.green[50],
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        i == 0
                                            ? "🥇"
                                            : i == 1
                                                ? "🥈"
                                                : i == 2
                                                    ? "🥉"
                                                    : "${i + 1}",
                                        style: TextStyle(
                                          fontSize: i < 3 ? 18 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.productName,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14)),
                                        Text(
                                            "${p.totalOrders} order${p.totalOrders == 1 ? '' : 's'}",
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[500])),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "KSh ${_fmt(p.totalRevenue)}",
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.green[700]),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Recent orders section
                      if (dashboard?.recentOrders != null &&
                          dashboard!.recentOrders!.isNotEmpty) ...[
                        Text("Recent Orders 📋",
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...dashboard!.recentOrders!.take(5).map(
                          (o) {
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      o.status == 'delivered'
                                          ? Icons.local_shipping_rounded
                                          : o.status == 'paid'
                                              ? Icons
                                                  .check_circle_rounded
                                              : Icons.access_time_rounded,
                                      color: statusColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Order #${o.orderId}",
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14)),
                                        if (o.consumerName != null)
                                          Text(o.consumerName!,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.grey[500])),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "KSh ${_fmt(o.totalPrice)}",
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.green[700]),
                                      ),
                                      Container(
                                        margin:
                                            const EdgeInsets.only(top: 3),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: statusColor
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          o.status,
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: statusColor,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _heroStat(String label, String value,
      {Color color = Colors.white}) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: color,
                fontSize: 22,
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
}