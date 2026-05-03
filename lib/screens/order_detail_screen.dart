import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import 'submit_rating_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  // We start with the order passed in, then optionally refresh
  // to get full item details if items list is empty.
  Order? order;
  bool isLoading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    order = widget.order;
    // If items weren't embedded in the list endpoint, fetch the detail
    if (order!.orderItems.isEmpty) {
      _fetchFullOrder();
    }
  }

  Future<void> _fetchFullOrder() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      final data = await ApiService.get("/orders/${order!.id}/");
      setState(() {
        order = Order.fromJson(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Could not load order details";
        isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'pending_delivery':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid ✅';
      case 'delivered':
        return 'Delivered 📦';
      case 'pending_delivery':
        return 'Pending Delivery 🚚';
      default:
        return 'Pending ⏳';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text(
          "Order #${order?.id ?? ''}",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFullOrder,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green))
          : error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(error,
                          style: GoogleFonts.poppins(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchFullOrder,
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Order header card ─────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order ID + date
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Order #${order!.id}",
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _statusColor(order!.status)
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _statusColor(order!.status)
                                            .withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    _statusLabel(order!.status),
                                    style: GoogleFonts.poppins(
                                      color:
                                          _statusColor(order!.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Date
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 5),
                                Text(
                                  _formatDate(order!.createdAt),
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[500]),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),

                            // Payment method
                            _infoRow(
                              Icons.payment_rounded,
                              "Payment",
                              order!.paymentMethod != null
                                  ? (order!.paymentMethod == 'pod'
                                      ? '💵 Pay on Delivery'
                                      : '📱 M-Pesa')
                                  : 'M-Pesa',
                              Colors.blue,
                            ),

                            // Delivery address
                            if (order!.deliveryAddress != null &&
                                order!.deliveryAddress!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _infoRow(
                                Icons.location_on_rounded,
                                "Delivery Address",
                                order!.deliveryAddress!,
                                Colors.red,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Items section ─────────────────────────────
                      Text(
                        "Items Ordered",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),

                      if (order!.orderItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              "No item details available",
                              style: GoogleFonts.poppins(
                                  color: Colors.grey[500]),
                            ),
                          ),
                        )
                      else
                        ...order!.orderItems.map(
                          (item) => Container(
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
                                // Product image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: item.productImage != null &&
                                          item.productImage!.isNotEmpty
                                      ? Image.network(
                                          item.productImage!,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              _imgPlaceholder(),
                                        )
                                      : _imgPlaceholder(),
                                ),

                                const SizedBox(width: 12),

                                // Name + qty
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        "Qty: ${item.quantity}  •  KSh ${item.price.toStringAsFixed(0)} each",
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),

                                // Line total
                                Text(
                                  "KSh ${(item.price * item.quantity).toStringAsFixed(0)}",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green[700]),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ── Total card ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[700]!,
                              Colors.green[500]!
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
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Order Total",
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              "KSh ${order!.totalPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Rate & Review button (delivered orders) ───
                      if (order!.isDelivered) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SubmitRatingScreen(order: order!),
                              ),
                            ),
                            icon: const Icon(Icons.star_rounded, size: 20),
                            label: Text(
                              "Rate & Review Products",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[500])),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
          child: Icon(Icons.grass, color: Colors.green, size: 28)),
    );
  }
}