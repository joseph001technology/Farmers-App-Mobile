import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? order;
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchOrder();
  }

  Future<void> fetchOrder() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final data = await ApiService.get("/orders/${widget.orderId}/");
      setState(() {
        order = Order.fromJson(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Failed to load order";
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
        return Colors.orange;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'delivered':
        return 'Delivered';
      case 'pending_delivery':
        return 'Pending Delivery';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text(
          "Order Details",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : order == null
                  ? const Center(child: Text("Order not found"))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 🔹 ORDER HEADER
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Order #${order!.id}",
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),

                                /// Status
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(order!.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(order!.status),
                                    style: GoogleFonts.poppins(
                                      color: _statusColor(order!.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  "Payment: ${order!.paymentMethod.toUpperCase()}",
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),

                                if (order!.deliveryAddress != null &&
                                    order!.deliveryAddress!.isNotEmpty)
                                  Text(
                                    "Delivery: ${order!.deliveryAddress}",
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// 🔹 ITEMS LIST
                          Text(
                            "Items",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),

                          ...order!.orderItems.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  /// Image
                                  if (item.productImage != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.productImage!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image),
                                    ),

                                  const SizedBox(width: 12),

                                  /// Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          "Qty: ${item.quantity}",
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// Price
                                  Text(
                                    "KSh ${(item.price * item.quantity).toStringAsFixed(0)}",
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 20),

                          /// 🔹 TOTAL
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total",
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 16),
                                ),
                                Text(
                                  "KSh ${order!.totalPrice.toStringAsFixed(0)}",
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// 🔹 RATE BUTTON (only if delivered)
                          if (order!.isDelivered)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showRatingDialog();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  "Rate Farmer",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  /// ⭐ RATING DIALOG (BEST UX APPROACH)
  void _showRatingDialog() {
    int stars = 5;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rate Farmer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: stars,
              items: List.generate(
                5,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text("${i + 1} Stars"),
                ),
              ),
              onChanged: (v) {
                if (v != null) stars = v;
              },
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Write a review (optional)",
              ),
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await ApiService.post("/ratings/", {
                "order": order!.id,
                "stars": stars,
                "review": controller.text
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Rating submitted")),
              );
            },
            child: const Text("Submit"),
          )
        ],
      ),
    );
  }
}