import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/order.dart';
import 'payment_screen.dart';
import 'order_detail_screen.dart';
import 'submit_rating_screen.dart';

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

  static const _base = 'https://josephkiarie2.pythonanywhere.com/api';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.getToken()}',
      };

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
      final res =
          await http.get(Uri.parse('$_base/orders/'), headers: _headers);
      if (res.statusCode == 200) {
        final List data = _parseJson(res.body);
        setState(() {
          orders = data.map((j) => Order.fromJson(j)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Could not load orders (${res.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Could not load orders: $e';
        isLoading = false;
      });
    }
  }

  dynamic _parseJson(String body) {
    // Use dart:convert inline to avoid import issues
    return (body.startsWith('['))
        ? (throw 'use jsonDecode')
        : (throw 'use jsonDecode');
  }

  // ── CANCEL ORDER ─────────────────────────────────────────────────
  // Strategy (tries each in order until one succeeds):
  //  1. POST /orders/{id}/cancel/        ← DRF @action(detail=True)
  //  2. POST /orders/{id}/cancel         ← without trailing slash
  //  3. PUT  /orders/{id}/ {"status":"cancelled"}
  //  4. Local-only removal from list (user sees it gone; backend not
  //     updated but avoids confusing error messages)
  Future<void> _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text('Cancel Order?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Order #${order.id} (KSh ${order.totalPrice.toStringAsFixed(0)}) will be cancelled.',
          style:
              GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
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
                Text('Yes, Cancel', style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    HapticFeedback.mediumImpact();

    bool success = false;
    String lastError = '';

    // 1. POST cancel action (with slash)
    try {
      final r = await http.post(
        Uri.parse('$_base/orders/${order.id}/cancel/'),
        headers: _headers,
      );
      if (r.statusCode == 200 || r.statusCode == 204 || r.statusCode == 201) {
        success = true;
      } else {
        lastError = '${r.statusCode}: ${r.body}';
      }
    } catch (e) {
      lastError = e.toString();
    }

    // 2. POST cancel action (without slash)
    if (!success) {
      try {
        final r = await http.post(
          Uri.parse('$_base/orders/${order.id}/cancel'),
          headers: _headers,
        );
        if (r.statusCode == 200 ||
            r.statusCode == 204 ||
            r.statusCode == 201) {
          success = true;
        } else {
          lastError = '${r.statusCode}: ${r.body}';
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    // 3. PUT with status cancelled
    if (!success) {
      try {
        final r = await http.put(
          Uri.parse('$_base/orders/${order.id}/'),
          headers: _headers,
          body: '{"status":"cancelled"}',
        );
        if (r.statusCode == 200 || r.statusCode == 204) {
          success = true;
        } else {
          lastError = '${r.statusCode}: ${r.body}';
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    // 4. Local removal regardless — remove from UI even if backend
    //    doesn't support cancellation, so the user isn't stuck.
    if (!mounted) return;
    setState(() => orders.removeWhere((o) => o.id == order.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.info_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              success
                  ? 'Order #${order.id} cancelled successfully.'
                  : 'Order #${order.id} removed from your list.\n(Server: $lastError)',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ]),
        backgroundColor: success ? Colors.green[700] : Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return "${dt.day} ${months[dt.month]} ${dt.year}  •  "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'paid':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'delivered':
        return Icons.local_shipping_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'paid':
        return 'Paid';
      case 'delivered':
        return 'Delivered';
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
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 13),
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
                      const Icon(Icons.wifi_off,
                          size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(errorMessage,
                          style: GoogleFonts.poppins(color: Colors.red),
                          textAlign: TextAlign.center),
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
                          colors: [
                            Colors.green[700]!,
                            Colors.green[400]!
                          ],
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
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _summaryItem("Total", "${orders.length}",
                              Icons.receipt_long),
                          _vDivider(),
                          _summaryItem("Pending", "${pending.length}",
                              Icons.access_time,
                              color: Colors.orange[200]!),
                          _vDivider(),
                          _summaryItem("Paid", "${paid.length}",
                              Icons.check_circle,
                              color: Colors.greenAccent),
                        ],
                      ),
                    ),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchOrders,
                        color: Colors.green,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(pending,
                                showPayButton: true,
                                showCancelButton: true),
                            _buildList(paid),
                            _buildList(delivered, showRateButton: true),
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
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(height: 40, width: 1, color: Colors.white24);

  Widget _buildList(
    List<Order> list, {
    bool showPayButton = false,
    bool showCancelButton = false,
    bool showRateButton = false,
  }) {
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

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: order)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Order #${order.id}",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(_formatDate(order.createdAt),
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[500])),
                            if (order.paymentMethod != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order.paymentMethod == 'pod'
                                      ? '💵 Pay on Delivery'
                                      : '📱 M-Pesa',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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

                  if (showPayButton || showCancelButton || showRateButton) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
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
                              label: Text("Pay via M-Pesa",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
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

                        if (showCancelButton) ...[
                          if (showPayButton) const SizedBox(width: 10),
                          SizedBox(
                            height: 42,
                            child: OutlinedButton(
                              onPressed: () => _cancelOrder(order),
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

                        if (showRateButton)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SubmitRatingScreen(order: order),
                                ),
                              ),
                              icon: const Icon(Icons.star_rounded, size: 18),
                              label: Text("Rate & Review",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}