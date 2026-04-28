import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import 'payment_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Order> orders = [];
  bool isLoading = true;
  String errorMessage = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final data = await ApiService.get("/orders/");
      setState(() {
        orders = (data as List).map((json) => Order.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Could not load orders: $e";
        isLoading = false;
      });
    }
  }

  /// Delete a pending order — confirm first, then call DELETE /orders/{id}/
  Future<void> _deleteOrder(Order order) async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Cancel Order?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Order #${order.id} (KSh ${order.totalPrice.toStringAsFixed(0)}) will be cancelled and removed.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep',
                style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                Text('Cancel Order', style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      HapticFeedback.mediumImpact();
      // Call DELETE /orders/{id}/ on your backend
      await ApiService.delete("/orders/${order.id}/");

      setState(() {
        orders.removeWhere((o) => o.id == order.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text('Order #${order.id} cancelled',
                style: GoogleFonts.poppins(fontSize: 13)),
          ]),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not cancel order: $e',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return "${dt.day} ${months[dt.month]} ${dt.year}  •  "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'delivered':
        return Icons.local_shipping_rounded;
      case 'pending':
      default:
        return Icons.access_time_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'delivered':
        return 'Delivered';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  List<Order> _filtered(String status) =>
      orders.where((o) => o.status == status).toList();

  @override
  Widget build(BuildContext context) {
    final pending = _filtered('pending');
    final paid = _filtered('paid');
    final delivered = _filtered('delivered');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text("My Orders",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green[700],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green[700],
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: "Pending (${pending.length})"),
            Tab(text: "Paid (${paid.length})"),
            Tab(text: "Delivered (${delivered.length})"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(errorMessage,
                          style: GoogleFonts.poppins(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: fetchOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary banner
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[700]!, Colors.green[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _summaryItem("Total", "${orders.length}",
                              Icons.receipt_long),
                          _divider(),
                          _summaryItem("Pending", "${pending.length}",
                              Icons.access_time,
                              color: Colors.orange[200]!),
                          _divider(),
                          _summaryItem(
                              "Paid", "${paid.length}", Icons.check_circle,
                              color: Colors.greenAccent),
                        ],
                      ),
                    ),

                    // Tabs
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchOrders,
                        color: Colors.green,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(pending,
                                showPayButton: true, showDeleteButton: true),
                            _buildList(paid),
                            _buildList(delivered),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon,
      {Color color = Colors.white}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _divider() {
    return Container(height: 40, width: 1, color: Colors.white24);
  }

  Widget _buildList(List<Order> list,
      {bool showPayButton = false, bool showDeleteButton = false}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 60, color: Colors.green[200]),
            const SizedBox(height: 12),
            Text("No orders here",
                style: GoogleFonts.poppins(
                    color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final order = list[index];
        final color = _statusColor(order.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Status icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_statusIcon(order.status),
                          color: color, size: 28),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order #${order.id}",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(_formatDate(order.createdAt),
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                    ),

                    // Price + status badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "KSh ${order.totalPrice.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.green[800]),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Text(
                            _statusLabel(order.status),
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Pay + Delete buttons for pending orders ────────────
                if (showPayButton || showDeleteButton) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Pay button
                      if (showPayButton)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(
                                    orderId: order.id,
                                    totalPrice: order.totalPrice,
                                  ),
                                ),
                              );
                              fetchOrders();
                            },
                            icon: const Text("📱",
                                style: TextStyle(fontSize: 15)),
                            label: Text(
                              "Pay via M-Pesa",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),

                      // Delete / Cancel button
                      if (showDeleteButton) ...[
                        if (showPayButton) const SizedBox(width: 10),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: () => _deleteOrder(order),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[600],
                              side: BorderSide(color: Colors.red[300]!),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined,
                                    size: 16, color: Colors.red[600]),
                                const SizedBox(width: 4),
                                Text('Cancel',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.red[600])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}