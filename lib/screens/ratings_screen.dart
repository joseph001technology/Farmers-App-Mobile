import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/rating_service.dart';
import '../services/farmer_service.dart';
import '../models/rating.dart';
import 'submit_rating_screen.dart';
import 'farmer_profile_screen.dart';
import '../widgets/farmer_avatar.dart';
import '../helpers/farmer_nav_helper.dart';

/// RatingsScreen
///
/// Usage A – farmer reviews (from HomeScreen / ProductDetail):
///   RatingsScreen(farmerId: 12, farmerName: 'John Mwangi')
///
/// Usage B – consumer's own reviews (from ConsumerDashboard):
///   RatingsScreen()   ← no args
class RatingsScreen extends StatefulWidget {
  final int?    farmerId;
  final String? farmerName;
  final int?    productId;
  final String? productName;

  const RatingsScreen({
    super.key,
    this.farmerId,
    this.farmerName,
    this.productId,
    this.productName,
  });

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen>
    with SingleTickerProviderStateMixin {
  FarmerRatingSummary? _summary;
  List<Rating>         _myRatings = [];
  FarmerProfile?       _farmerProfile;
  bool   _loading = true;
  String _error   = '';
  late AnimationController _animCtrl;

  bool get _isFarmerMode => widget.farmerId != null;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _load();
    if (_isFarmerMode) _loadFarmerProfile();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFarmerProfile() async {
    try {
      final p = await FarmerService.getFarmerProfile(widget.farmerId!);
      if (mounted) setState(() => _farmerProfile = p);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      if (_isFarmerMode) {
        final s = await RatingService.getFarmerRatingById(widget.farmerId!);
        setState(() { _summary = s; _loading = false; });
      } else {
        final r = await RatingService.getMyRatings();
        setState(() { _myRatings = r; _loading = false; });
      }
      _animCtrl.forward();
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _goRate({int? farmerId, String? farmerName}) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitRatingScreen(
          preselectedFarmerId:   farmerId   ?? widget.farmerId,
          preselectedFarmerName: farmerName ?? widget.farmerName,
        ),
      ),
    );
    if (submitted == true) _load();
  }

  String get _title => _isFarmerMode
      ? '${widget.farmerName ?? _summary?.farmerName ?? 'Farmer'} Reviews'
      : 'My Reviews';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error.isNotEmpty
              ? _errorView()
              : _isFarmerMode
                  ? _farmerView()
                  : _myReviewsView(),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // FARMER VIEW
  // ══════════════════════════════════════════════════════════════════
  Widget _farmerView() {
    final s          = _summary!;
    final photoUrl   = _farmerProfile?.profilePhoto;
    final farmerName = s.farmerName.isNotEmpty ? s.farmerName
        : widget.farmerName ?? 'Farmer';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            // View Profile button
            if (widget.farmerId != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FarmerProfileScreen(
                        farmerId:   widget.farmerId!,
                        farmerName: farmerName,
                      ))),
                  icon: const Icon(Icons.person_outline),
                  label: Text('View Profile',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal[700],
                    side: BorderSide(color: Colors.teal[400]!, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _goRate(),
                icon: const Icon(Icons.rate_review_rounded),
                label: Text('Rate Farmer',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 270,
            pinned: true,
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green[900]!, Colors.teal[600]!],
                    ),
                  ),
                ),
                Positioned(top: -30, right: -30,
                    child: _circle(160, Colors.white.withOpacity(0.05))),
                Positioned(bottom: -20, left: -20,
                    child: _circle(120, Colors.white.withOpacity(0.05))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile photo
                      GestureDetector(
                        onTap: widget.farmerId == null ? null : () =>
                            goToFarmerProfile(context, farmerId: widget.farmerId, farmerName: farmerName),
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(photoUrl),
                                backgroundColor: Colors.white.withOpacity(0.2),
                                onBackgroundImageError: (_, _) {},
                              )
                            : FarmerAvatar(
                                farmerId:        widget.farmerId,
                                farmerName:      farmerName,
                                radius:          40,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                textColor:       Colors.white,
                              ),
                      ),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(farmerName,
                            style: GoogleFonts.poppins(
                                fontSize: 20, fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                      ]),
                      const SizedBox(height: 4),
                      Text('🌾 Local Farmer • Nairobi, Kenya',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ...List.generate(5, (i) => Icon(
                          i < s.averageRating.floor()
                              ? Icons.star_rounded
                              : (i < s.averageRating
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded),
                          color: Colors.amber, size: 22,
                        )),
                        const SizedBox(width: 8),
                        Text(s.averageRating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Text('(${s.totalRatings} reviews)',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.white70)),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(children: [
              _statsStrip(s),
              const SizedBox(height: 16),
              _distributionCard(s),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer Reviews',
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('${s.ratings.length} total',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (s.ratings.isEmpty)
                _emptyReviews()
              else
                ...s.ratings.take(10).map(_reviewCard),
              const SizedBox(height: 80),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statsStrip(FarmerRatingSummary s) => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      _stripStat('⭐', s.averageRating.toStringAsFixed(1), 'Overall Rating'),
      _vDivider(),
      _stripStat('💬', '${s.totalRatings}', 'Reviews'),
      _vDivider(),
      _stripStat('🥇', _topLabel(s), 'Top Category'),
    ]),
  );

  String _topLabel(FarmerRatingSummary s) {
    if (s.totalRatings == 0) return 'N/A';
    final fives = s.ratings.where((r) => r.stars == 5).length;
    final pct   = (fives / s.totalRatings * 100).round();
    if (pct >= 60) return '$pct% 5★';
    if (s.averageRating >= 4) return 'Excellent';
    if (s.averageRating >= 3) return 'Good';
    return 'Average';
  }

  Widget _stripStat(String emoji, String value, String label) => Expanded(
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
      Text(label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
          textAlign: TextAlign.center),
    ]),
  );

  Widget _vDivider() =>
      Container(height: 40, width: 1, color: Colors.grey[200]);

  Widget _distributionCard(FarmerRatingSummary s) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: [Colors.amber[700]!, Colors.orange[500]!],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.averageRating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
                fontSize: 52, fontWeight: FontWeight.bold,
                color: Colors.white, height: 1)),
        Row(children: List.generate(5, (i) => Icon(
          i < s.averageRating.floor()
              ? Icons.star_rounded
              : (i < s.averageRating
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded),
          color: Colors.white, size: 18,
        ))),
        const SizedBox(height: 4),
        Text('${s.totalRatings} review${s.totalRatings == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
      ]),
      const Spacer(),
      Column(children: List.generate(5, (i) {
        final star  = 5 - i;
        final count = s.ratings.where((r) => r.stars == star).length;
        final pct   = s.totalRatings == 0 ? 0.0 : count / s.totalRatings;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Text('$star',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.star, color: Colors.white, size: 12),
            const SizedBox(width: 8),
            SizedBox(
              width: 90, height: 7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text('$count',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
          ]),
        );
      })),
    ]),
  );

  Widget _reviewCard(Rating r) {
    final initials = r.consumerName.isNotEmpty
        ? r.consumerName[0].toUpperCase() : '?';
    final dateStr  = r.createdAt.length >= 10
        ? r.createdAt.substring(0, 10) : r.createdAt;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green[100],
            child: Text(initials,
                style: GoogleFonts.poppins(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.consumerName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(dateStr,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${r.stars}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13, color: Colors.amber[800])),
              const SizedBox(width: 3),
              Icon(Icons.star_rounded, color: Colors.amber[700], size: 14),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: List.generate(5, (i) => Icon(
          i < r.stars ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber, size: 15,
        ))),
        if (r.review != null && r.review!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(r.review!,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[700], height: 1.5)),
        ],
      ]),
    );
  }

  Widget _emptyReviews() => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      const Text('⭐', style: TextStyle(fontSize: 50)),
      const SizedBox(height: 12),
      Text('No reviews yet',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
      Text('Be the first to review this farmer!',
          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
    ]),
  );

  // ══════════════════════════════════════════════════════════════════
  // MY REVIEWS VIEW
  // ══════════════════════════════════════════════════════════════════
  Widget _myReviewsView() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      backgroundColor: const Color(0xFFF5F9F0),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _goRate(),
              icon: const Icon(Icons.add_comment_rounded),
              label: Text('Add a Review',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
      body: _myRatings.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('📝', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No reviews yet',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Your reviews will appear here',
                style: GoogleFonts.poppins(color: Colors.grey[500])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _goRate(),
              icon: const Icon(Icons.rate_review_rounded),
              label: Text('Write your first review',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ]))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.green[700]!, Colors.teal[500]!]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Text('⭐', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '${_myRatings.length} review${_myRatings.length == 1 ? '' : 's'} submitted',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Thank you for supporting local farmers!',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 12)),
                    ])),
                  ]),
                ),
                ..._myRatings.map(_myReviewCard),
              ],
            ),
    );
  }

  Widget _myReviewCard(Rating r) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        // Farmer avatar with photo
        FarmerAvatar(
          farmerId:   null, // We don't have farmerId in Rating model here
          farmerName: r.farmerName,
          radius:     20,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.farmerName,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Text('Order #${r.order}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey[400])),
        ])),
        Row(children: List.generate(5, (i) => Icon(
          i < r.stars ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber, size: 16,
        ))),
      ]),
      if (r.review != null && r.review!.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(r.review!,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[700], height: 1.4),
              maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
      ],
      const SizedBox(height: 8),
      Text(
        r.createdAt.length >= 10 ? r.createdAt.substring(0, 10) : r.createdAt,
        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
      ),
    ]),
  );

  // ── Error view ──────────────────────────────────────────────────────
  Widget _errorView() => Scaffold(
    appBar: AppBar(
      title: Text(_title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      centerTitle: true, backgroundColor: Colors.white,
      foregroundColor: Colors.black87, elevation: 0,
    ),
    backgroundColor: const Color(0xFFF5F9F0),
    body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
      const SizedBox(height: 12),
      Text('Could not load reviews',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(_error,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center),
      ),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white),
      ),
    ])),
  );

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}