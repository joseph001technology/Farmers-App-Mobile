import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../helpers/api_helper.dart'; // Updated to match your helper name
import '../services/auth_service.dart';
import 'orders_screen.dart';
import 'order_detail_screen.dart'; // Import this instead of ReceiptScreen

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final double totalPrice;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.totalPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = AuthService.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _payWithMpesa() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your phone number")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiHelper.post("/payments/mpesa/stk-push/", {
        "phone": phone,
        "order_id": widget.orderId,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ResponseCode'] == '0') {
        if (!mounted) return;
        _showAwaitingDialog();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data.toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAwaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _AwaitingPaymentDialog(
        orderId: widget.orderId,
        totalPrice: widget.totalPrice,
        onPaid: (order) {
          Navigator.of(dialogCtx).pop();
          _showReceiptPrompt(order);
        },
        onTimeout: () {
          Navigator.of(dialogCtx).pop();
          _showTimeoutDialog();
        },
        onSkip: () {
          Navigator.of(dialogCtx).pop();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const OrdersScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  void _showReceiptPrompt(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 38, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('Payment Confirmed! 🎉',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Your order is now being processed',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order #${widget.orderId}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                            Text('KSh ${widget.totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                          ],
                        ),
                        const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 32),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // REDIRECT TO ORDER DETAIL
                        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
                      },
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: Text('View Receipt', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const OrdersScreen()),
                          (route) => false,
                        );
                      },
                      icon: Icon(Icons.list_alt_rounded, color: Colors.green[700]),
                      label: Text('View My Orders',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.green[700])),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.green.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 56, color: Colors.orange),
            const SizedBox(height: 14),
            Text('Payment Pending', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("We haven't received confirmation yet. If you entered your PIN, payment will reflect shortly in My Orders.",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Go to My Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text("Pay with M-Pesa", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[400]!],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Text("Order #${widget.orderId}", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("KSh ${widget.totalPrice.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Total to pay", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Text("📱", style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text("M-Pesa STK Push", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.green[800])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text("Enter M-Pesa Phone Number", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "e.g. 0712345678",
                prefixIcon: const Icon(Icons.phone, color: Colors.green),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade200),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You will receive an M-Pesa prompt on your phone. Enter your PIN to complete payment.",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _payWithMpesa,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.payment),
                label: Text(_isLoading ? "Sending prompt..." : "Pay KSh ${widget.totalPrice.toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _AwaitingPaymentDialog extends StatefulWidget {
  final int orderId;
  final double totalPrice;
  final void Function(Order order) onPaid;
  final VoidCallback onTimeout;
  final VoidCallback onSkip;

  const _AwaitingPaymentDialog({
    required this.orderId,
    required this.totalPrice,
    required this.onPaid,
    required this.onTimeout,
    required this.onSkip,
  });

  @override
  State<_AwaitingPaymentDialog> createState() => _AwaitingPaymentDialogState();
}

class _AwaitingPaymentDialogState extends State<_AwaitingPaymentDialog> {
  int _attempt = 0;
  static const int _maxAttempts = 10;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _startPolling() async {
    while (_attempt < _maxAttempts && !_cancelled) {
      await Future.delayed(const Duration(seconds: 3));
      if (_cancelled) return;

      _attempt++;
      if (mounted) setState(() {});

      try {
        final res = await ApiHelper.get("/orders/${widget.orderId}/");
        if (_cancelled) return;
        final data = jsonDecode(res.body);
        final order = Order.fromJson(data as Map<String, dynamic>);
        if (order.status == 'paid' || order.status == 'delivered') {
          if (!_cancelled) widget.onPaid(order);
          return;
        }
      } catch (_) {}
    }
    if (!_cancelled) widget.onTimeout();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _attempt / _maxAttempts;
    final secondsLeft = (_maxAttempts - _attempt) * 3;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[700]!, Colors.green[400]!],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const Text('📱', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Check Your Phone',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Enter your M-Pesa PIN to confirm', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order #${widget.orderId}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                      Text('KSh ${widget.totalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[700])),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.green[700], strokeWidth: 2.5)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Waiting for payment confirmation...', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]))),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey[200], color: Colors.green[600]),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('~${secondsLeft}s remaining', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: Text("I'll check later — Go to My Orders",
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}