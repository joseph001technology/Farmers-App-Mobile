import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/api_helper.dart';
import '../models/order.dart';
import '../services/rating_service.dart';
import '../services/farmer_service.dart';
import '../widgets/farmer_avatar.dart';

class SubmitRatingScreen extends StatefulWidget {
  final Order? order;
  final int?    preselectedFarmerId;
  final String? preselectedFarmerName;

  const SubmitRatingScreen({
    super.key,
    this.order,
    this.preselectedFarmerId,
    this.preselectedFarmerName,
  });

  @override
  State<SubmitRatingScreen> createState() => _SubmitRatingScreenState();
}

class _SubmitRatingScreenState extends State<SubmitRatingScreen> {
  int    _selectedStars = 5;
  final  _reviewCtrl    = TextEditingController();
  bool   _isSubmitting  = false;
  bool   _alreadyRated  = false;

  List<Map<String, dynamic>> _deliveredOrders = [];
  int?    _selectedOrderId;
  int?    _selectedFarmerId;
  String? _selectedFarmerName;
  bool    _loadingOrders   = false;
  String  _ordersError     = '';

  List<Map<String, dynamic>> _farmers        = [];
  bool                       _loadingFarmers = false;
  Map<String, dynamic>?      _pickedFarmer;

  // Profile photo URLs
  String? _farmerPhotoUrl;

  static const _labels = [
    '', 'Poor 😞', 'Fair 😐', 'Good 🙂', 'Great 😄', 'Excellent 🌟'
  ];

  bool get _isModeA          => widget.order != null;
  bool get _hasFarmerPreset  => widget.preselectedFarmerId != null;

  @override
  void initState() {
    super.initState();
    if (_isModeA) {
      _selectedFarmerId   = _resolveFarmerIdFromOrder();
      _selectedFarmerName = _resolveFarmerNameFromOrder();
      _selectedOrderId    = widget.order!.id;
    } else {
      _selectedFarmerId   = widget.preselectedFarmerId;
      _selectedFarmerName = widget.preselectedFarmerName;
      _loadDeliveredOrders();
      if (!_hasFarmerPreset) _loadFarmers();
    }
    // Load profile photo if we have a farmer ID
    if (_selectedFarmerId != null) _loadFarmerPhoto(_selectedFarmerId!);
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFarmerPhoto(int farmerId) async {
    try {
      final profile = await FarmerService.getFarmerProfile(farmerId);
      if (mounted && profile?.profilePhoto != null) {
        setState(() => _farmerPhotoUrl = profile!.profilePhoto);
      }
    } catch (_) {}
  }

  int? _resolveFarmerIdFromOrder() {
    try {
      final id = (widget.order! as dynamic).farmerId;
      if (id != null) return id as int;
    } catch (_) {}
    return null;
  }

  String _resolveFarmerNameFromOrder() {
    try {
      final n = (widget.order! as dynamic).farmerName as String?;
      if (n != null && n.isNotEmpty) return n;
    } catch (_) {}
    return 'Farmer';
  }

  String get _farmerName =>
      _selectedFarmerName ??
      _pickedFarmer?['username']?.toString() ??
      'Farmer';

  int? get _farmerId =>
      _selectedFarmerId ??
      (_pickedFarmer?['id'] as num?)?.toInt();

  Future<void> _loadDeliveredOrders() async {
    setState(() { _loadingOrders = true; _ordersError = ''; });
    try {
      final res = await ApiHelper.get('/orders/');
      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body) as List;
        final delivered = raw
            .cast<Map<String, dynamic>>()
            .where((o) => o['status'] == 'delivered' || o['status'] == 'paid')
            .toList();
        setState(() { _deliveredOrders = delivered; _loadingOrders = false; });
      } else {
        setState(() {
          _ordersError   = 'Could not load orders (${res.statusCode})';
          _loadingOrders = false;
        });
      }
    } catch (e) {
      setState(() { _ordersError = e.toString(); _loadingOrders = false; });
    }
  }

  Future<void> _loadFarmers() async {
    setState(() => _loadingFarmers = true);
    try {
      final res = await ApiHelper.get('/products/');
      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body) as List;
        final seen    = <int>{};
        final farmers = <Map<String, dynamic>>[];
        for (final p in raw.cast<Map<String, dynamic>>()) {
          final fId = (p['farmer'] as num?)?.toInt() ??
              (p['farmer_id'] as num?)?.toInt();
          final fName = p['farmer_name']?.toString() ??
              p['farmer_username']?.toString();
          final fPhoto = p['farmer_photo']?.toString() ??
              p['farmer_profile_photo']?.toString();
          if (fId != null && !seen.contains(fId)) {
            seen.add(fId);
            farmers.add({
              'id': fId,
              'username': fName ?? 'Farmer #$fId',
              'photo': fPhoto,
            });
          }
        }
        setState(() { _farmers = farmers; _loadingFarmers = false; });
      } else {
        setState(() => _loadingFarmers = false);
      }
    } catch (_) {
      setState(() => _loadingFarmers = false);
    }
  }

  Future<void> _submit() async {
    final fId = _farmerId;
    final oId = _selectedOrderId;

    if (fId == null) {
      _snack('Please select a farmer to rate.', isError: true);
      return;
    }
    if (oId == null) {
      _snack('Please select which order you are rating.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await RatingService.submitRating(
        farmerId: fId,
        orderId:  oId,
        stars:    _selectedStars,
        review:   _reviewCtrl.text.trim().isEmpty
            ? null : _reviewCtrl.text.trim(),
      );
      if (!mounted) return;
      _snack('Review submitted! Thank you 🌟');
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('already rated') ||
          msg.toLowerCase().contains('already rate')) {
        setState(() => _alreadyRated = true);
      }
      _snack(msg, isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text('Rate a Farmer',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _farmerCard(),
          const SizedBox(height: 16),

          if (!_isModeA && !_hasFarmerPreset) ...[
            _farmerPickerCard(),
            const SizedBox(height: 16),
          ],

          if (!_isModeA) ...[
            _orderPickerCard(),
            const SizedBox(height: 16),
          ],

          if (_isModeA) ...[
            _orderSummaryCard(),
            const SizedBox(height: 16),
          ],

          if (_alreadyRated)
            _noticeBanner(
              icon: Icons.info_outline,
              message: 'You have already rated this order.',
              color: Colors.orange,
            ),

          if (!_alreadyRated) _ratingForm(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Farmer profile card ──────────────────────────────────────────────
  Widget _farmerCard() {
    final name      = _farmerName;
    final photoUrl  = _farmerPhotoUrl;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[800]!, Colors.teal[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🌾', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('Your Farmer',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        // Profile photo
        photoUrl != null && photoUrl.isNotEmpty
            ? CircleAvatar(
                radius: 44,
                backgroundImage: NetworkImage(photoUrl),
                backgroundColor: Colors.white.withOpacity(0.2),
                onBackgroundImageError: (_, _) {},
              )
            : FarmerAvatar(
                farmerId:        _farmerId,
                farmerName:      name,
                radius:          44,
                backgroundColor: Colors.white.withOpacity(0.2),
                textColor:       Colors.white,
              ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(name,
              style: GoogleFonts.poppins(
                  fontSize: 20, color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          const Icon(Icons.verified, color: Colors.greenAccent, size: 18),
        ]),
        const SizedBox(height: 4),
        Text('🇰🇪 Nairobi, Kenya',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
        if (_isModeA) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Order #${widget.order!.id}  •  ${_statusLabel(widget.order!.status)}',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ]),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'delivered': return '✅ Delivered';
      case 'paid':      return '💳 Paid';
      default:          return s;
    }
  }

  // ── Farmer picker (Mode C) ───────────────────────────────────────────
  Widget _farmerPickerCard() {
    if (_loadingFarmers) return _loadingCard('Loading farmers…');
    if (_farmers.isEmpty) {
      return _noticeBanner(
        icon: Icons.info_outline,
        message: 'No farmers found. Place an order first.',
        color: Colors.blue,
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Select Farmer',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green[800])),
        Text('Who would you like to rate?',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 12),
        DropdownButtonFormField<Map<String, dynamic>>(
          initialValue: _pickedFarmer,
          hint: Text('Choose a farmer',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: const Icon(Icons.agriculture_outlined),
          ),
          items: _farmers.map((f) {
            final label  = f['username']?.toString() ?? 'Farmer';
            final fId    = (f['id'] as num?)?.toInt();
            final fPhoto = f['photo']?.toString();
            return DropdownMenuItem(
              value: f,
              child: Row(children: [
                fPhoto != null && fPhoto.isNotEmpty
                    ? CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(fPhoto),
                        backgroundColor: Colors.green[100],
                        onBackgroundImageError: (_, _) {},
                      )
                    : FarmerAvatar(
                        farmerId:   fId,
                        farmerName: label,
                        radius:     14,
                      ),
                const SizedBox(width: 10),
                Text(label, style: GoogleFonts.poppins(fontSize: 13)),
              ]),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _pickedFarmer       = v;
              _selectedFarmerId   = (v?['id'] as num?)?.toInt();
              _selectedFarmerName = v?['username']?.toString();
              _farmerPhotoUrl     = v?['photo']?.toString();
            });
            final fId = (v?['id'] as num?)?.toInt();
            if (fId != null) _loadFarmerPhoto(fId);
          },
        ),
      ]),
    );
  }

  // ── Order picker (Mode B/C) ──────────────────────────────────────────
  Widget _orderPickerCard() {
    if (_loadingOrders) return _loadingCard('Loading your orders…');
    if (_ordersError.isNotEmpty) {
      return _noticeBanner(
          icon: Icons.error_outline, message: _ordersError, color: Colors.red);
    }
    if (_deliveredOrders.isEmpty) {
      return _noticeBanner(
        icon: Icons.receipt_long_outlined,
        message: 'No delivered orders found. You can only rate after an order is delivered.',
        color: Colors.orange,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Select Order',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green[800])),
        Text('Which order are you rating?',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _selectedOrderId,
          hint: Text('Choose an order',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: const Icon(Icons.receipt_outlined),
          ),
          items: _deliveredOrders.map((o) {
            final id     = (o['id'] as num).toInt();
            final status = o['status']?.toString() ?? '';
            final total  = double.tryParse(
                    o['total_price']?.toString() ?? '0') ?? 0.0;
            return DropdownMenuItem(
              value: id,
              child: Text(
                'Order #$id  •  KSh ${total.toStringAsFixed(0)}  •  $status',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedOrderId = v),
        ),
      ]),
    );
  }

  // ── Mode A: order items summary ──────────────────────────────────────
  Widget _orderSummaryCard() {
    final items = widget.order?.orderItems ?? [];
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Items in this order',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Icon(Icons.circle, size: 6, color: Colors.green[600]),
            const SizedBox(width: 8),
            Expanded(child: Text(item.productName,
                style: GoogleFonts.poppins(fontSize: 13))),
            Text('×${item.quantity}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
          ]),
        )),
      ]),
    );
  }

  // ── Rating form ──────────────────────────────────────────────────────
  Widget _ratingForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green[100]!),
        boxShadow: [BoxShadow(
            color: Colors.green.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How was your experience?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 16,
                color: Colors.green[800])),
        Text('with $_farmerName',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 20),

        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedStars = star),
                child: AnimatedScale(
                  scale: _selectedStars == star ? 1.3 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      star <= _selectedStars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: star <= _selectedStars
                          ? Colors.amber
                          : Colors.grey[300],
                      size: 42,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_labels[_selectedStars],
                style: GoogleFonts.poppins(
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ),

        const SizedBox(height: 20),

        Text('Your review (optional)',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewCtrl,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Share your experience with this farmer…',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[400]!)),
            contentPadding: const EdgeInsets.all(14),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: Text(
              _isSubmitting ? 'Submitting…' : 'Submit Review',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 6, offset: const Offset(0, 2))],
  );

  Widget _loadingCard(String msg) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecor(),
    child: Row(children: [
      const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
      const SizedBox(width: 14),
      Text(msg, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
    ]),
  );

  Widget _noticeBanner({
    required IconData      icon,
    required String        message,
    required MaterialColor color,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color[200]!),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color[700], size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: GoogleFonts.poppins(color: color[800], fontSize: 13))),
        ]),
      );
}