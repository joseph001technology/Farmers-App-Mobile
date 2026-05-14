import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/farmer_service.dart';
import 'submit_rating_screen.dart';
import 'farmer_profile_screen.dart';
import '../widgets/farmer_avatar.dart';
import '../helpers/farmer_nav_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  Order?         order;
  FarmerProfile? _farmerProfile;
  bool   isLoading = false;
  String error     = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    order = widget.order;
    if (order!.orderItems.isEmpty) _fetchFullOrder();
    _loadFarmerProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmerProfile() async {
    final farmerId = order?.farmerId;
    if (farmerId == null) return;
    try {
      final p = await FarmerService.getFarmerProfile(farmerId);
      if (mounted) setState(() => _farmerProfile = p);
    } catch (_) {}
  }

  Future<void> _fetchFullOrder() async {
    setState(() { isLoading = true; error = ''; });
    try {
      final data = await ApiService.get("/orders/${order!.id}/");
      setState(() {
        order     = Order.fromJson(data);
        isLoading = false;
      });
      _loadFarmerProfile();
    } catch (e) {
      setState(() { error = "Could not load order details"; isLoading = false; });
    }
  }

  Future<void> _printReceipt() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 40, height: 40,
                      decoration: const pw.BoxDecoration(
                          color: PdfColors.green, shape: pw.BoxShape.circle),
                      child: pw.Center(
                        child: pw.Text("A",
                            style: pw.TextStyle(color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold, fontSize: 20)),
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text("AGRIFLOW",
                          style: pw.TextStyle(fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800, letterSpacing: 2)),
                      pw.Text("Official Payment Receipt",
                          style: pw.TextStyle(fontSize: 12,
                              color: PdfColors.grey700,
                              fontStyle: pw.FontStyle.italic)),
                    ]),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 15),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("RECEIPT FOR:",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text("Order #${order!.id}",
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        border: pw.Border.all(color: PdfColors.green, width: 1)),
                    child: pw.Text("PAID",
                        style: pw.TextStyle(fontSize: 18, color: PdfColors.green,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                ]),
                pw.SizedBox(height: 20),
                pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("Merchant:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(order!.farmerName ?? 'Local Farmer'),
                    pw.SizedBox(height: 10),
                    pw.Text("Billed To:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(order!.deliveryAddress ?? "Customer / Self Collection"),
                  ])),
                  pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text("Date Issued:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(_formatDate(order!.createdAt)),
                    pw.SizedBox(height: 10),
                    pw.Text("Payment Method:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(order!.paymentMethod == 'pod' ? 'Pay on Delivery' : 'M-Pesa'),
                  ])),
                ]),
                pw.SizedBox(height: 30),
                pw.Text("ITEMIZED SUMMARY",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                        fontSize: 12, color: PdfColors.grey700)),
                pw.Divider(thickness: 0.5),
                ...order!.orderItems.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Expanded(child: pw.Text("${item.productName} (x${item.quantity})",
                        style: const pw.TextStyle(fontSize: 11))),
                    pw.Text("KSh ${(item.price * item.quantity).toStringAsFixed(0)}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ]),
                )),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1.5),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("TOTAL PAID",
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("KSh ${order!.totalPrice.toStringAsFixed(0)}",
                      style: pw.TextStyle(fontSize: 18,
                          fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                ]),
                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.Center(child: pw.Column(children: [
                  pw.Text("Thank you for using Agriflow to support local agriculture!",
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic,
                          fontSize: 10, color: PdfColors.grey600)),
                  pw.SizedBox(height: 5),
                  pw.Text("This is a computer-generated receipt and does not require a signature.",
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ])),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':             return Colors.green;
      case 'delivered':        return Colors.blue;
      case 'pending_delivery': return Colors.purple;
      case 'cancelled':        return Colors.red;
      default:                 return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':             return 'Paid ✅';
      case 'delivered':        return 'Delivered 📦';
      case 'pending_delivery': return 'Pending Delivery 🚚';
      case 'cancelled':        return 'Cancelled ❌';
      default:                 return 'Pending ⏳';
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${dt.day} ${months[dt.month]} ${dt.year}  •  "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return raw;
    }
  }

  void _goToFarmerProfile() {
    goToFarmerProfile(
      context,
      farmerId:   order?.farmerId,
      farmerName: order?.farmerName ?? 'Farmer',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text("Order Details",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchFullOrder),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green[700],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green[700],
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline_rounded), text: 'Info'),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Receipt'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : error.isNotEmpty
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildDetailsTab(), _buildReceiptTab()],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 60, color: Colors.grey),
      const SizedBox(height: 12),
      Text(error, style: GoogleFonts.poppins(color: Colors.red)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _fetchFullOrder,
        icon: const Icon(Icons.refresh),
        label: const Text("Retry"),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700], foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ]));
  }

  Widget _buildDetailsTab() {
    final farmerId   = order?.farmerId;
    final farmerName = order?.farmerName ?? 'Local Farmer';
    final photoUrl = _farmerProfile?.profilePhoto ?? order?.farmerImage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Farmer profile banner (clickable) ─────────────────────
        if (farmerId != null)
          GestureDetector(
            onTap: _goToFarmerProfile,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.teal[500]!],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.green.withOpacity(0.25),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                // Profile photo
                photoUrl != null && photoUrl.isNotEmpty
                    ? CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(photoUrl),
                        backgroundColor: Colors.white.withOpacity(0.2),
                        onBackgroundImageError: (_, _) {},
                      )
                    : FarmerAvatar(
                        farmerId:        farmerId,
                        farmerName:      farmerName,
                        radius:          28,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        textColor:       Colors.white,
                      ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(farmerName,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified, color: Colors.greenAccent, size: 14),
                  ]),
                  Text('Tap to view farmer profile',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 11)),
                ])),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
              ]),
            ),
          ),

        // ── Order info card ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Order #${order!.id}",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(order!.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor(order!.status).withOpacity(0.4)),
                ),
                child: Text(_statusLabel(order!.status),
                    style: GoogleFonts.poppins(
                        color: _statusColor(order!.status),
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text(_formatDate(order!.createdAt),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
            ]),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _infoRow(Icons.person_pin_rounded, "Farmer / Merchant",
                order!.farmerName ?? "Local Farmer", Colors.green),
            const SizedBox(height: 10),
            _infoRow(Icons.payment_rounded, "Payment",
                order!.paymentMethod != null
                    ? (order!.paymentMethod == 'pod'
                        ? '💵 Pay on Delivery' : '📱 M-Pesa')
                    : 'M-Pesa',
                Colors.blue),
            if (order!.deliveryAddress != null &&
                order!.deliveryAddress!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(Icons.location_on_rounded, "Delivery Address",
                  order!.deliveryAddress!, Colors.red),
            ],
          ]),
        ),

        const SizedBox(height: 20),
        Text("Items Ordered",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),

        if (order!.orderItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text("No item details available",
                style: GoogleFonts.poppins(color: Colors.grey[500]))),
          )
        else
          ...order!.orderItems.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.productImage != null && item.productImage!.isNotEmpty
                    ? Image.network(item.productImage!,
                        width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _imgPlaceholder())
                    : _imgPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.productName,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text("Qty: ${item.quantity}  •  KSh ${item.price.toStringAsFixed(0)} each",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
              ])),
              Text("KSh ${(item.price * item.quantity).toStringAsFixed(0)}",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, color: Colors.green[700])),
            ]),
          )),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.green[700]!, Colors.green[500]!],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Order Total",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
            Text("KSh ${order!.totalPrice.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ]),
        ),

        const SizedBox(height: 20),

        // Action buttons row
        Row(children: [
          // View Farmer Profile
          if (farmerId != null) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToFarmerProfile,
                icon: const Icon(Icons.person_outline, size: 16),
                label: Text('Farmer Profile',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal[700],
                  side: BorderSide(color: Colors.teal[400]!, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Rate & Review
          if (order!.isDelivered)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SubmitRatingScreen(order: order!))),
                icon: const Icon(Icons.star_rounded, size: 18),
                label: Text("Rate & Review",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
        ]),

        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildReceiptTab() {
    final canShow = order!.status == 'paid' ||
        order!.status == 'delivered' ||
        order!.status == 'pending_delivery';

    if (!canShow) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Receipt not available yet',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text('Receipt will appear here once\nyour payment is confirmed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400])),
      ]));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Text("ORDER RECEIPT",
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: Colors.green, letterSpacing: 1.2)),
            const SizedBox(height: 20),
            Text('Order #${order!.id}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 4),
            Text(_formatDate(order!.createdAt),
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 20),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            _quickRow('Farmer', order!.farmerName ?? 'Local Farmer'),
            const SizedBox(height: 8),
            _quickRow('Items Count', '${order!.orderItems.length} items'),
            const SizedBox(height: 8),
            _quickRow('Payment Via',
                order!.paymentMethod == 'pod' ? 'Pay on Delivery' : 'M-Pesa'),
            const SizedBox(height: 8),
            _quickRow('Current Status', order!.status.toUpperCase()),
            const SizedBox(height: 20),
            const Divider(thickness: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 16),
            ...order!.orderItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("${item.productName} x${item.quantity}",
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                Text("KSh ${(item.price * item.quantity).toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            )),
            const SizedBox(height: 20),
            const Divider(thickness: 1),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('TOTAL PAID',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('KSh ${order!.totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900, fontSize: 24,
                      color: Colors.green[700])),
            ]),
            const SizedBox(height: 10),
            Text("Support local agriculture with every purchase.",
                style: GoogleFonts.poppins(
                    fontSize: 11, fontStyle: FontStyle.italic,
                    color: Colors.grey[500])),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton.icon(
            onPressed: _printReceipt,
            icon: const Icon(Icons.print_rounded),
            label: Text('Download / Print PDF',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
          ),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _quickRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
      Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        ])),
      ]);

  Widget _imgPlaceholder() => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
        color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
    child: const Center(child: Icon(Icons.grass, color: Colors.green, size: 28)),
  );
}