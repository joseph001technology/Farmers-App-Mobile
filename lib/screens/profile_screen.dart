import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../helpers/api_helper.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'profile_edit_screen.dart';
import 'farmer_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'consumer_dashboard_screen.dart';
import 'ratings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;

  // Profile fields
  String? profilePhoto;
  String? location;
  String? bio;
  String? farmSize;
  double? averageRating;
  int?    totalRatings;

  // Stats computed from orders
  int    _totalOrders    = 0;
  int    _deliveredCount = 0;
  int    _pendingCount   = 0;
  double _totalSpent     = 0;
  int    _productCount   = 0; // farmer: products listed

  // Animation
  late AnimationController _animCtrl;
  late Animation<double>    _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadAll();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => isLoading = true);
    await Future.wait([_loadProfile(), _loadStats()]);
    setState(() => isLoading = false);
    _animCtrl.forward(from: 0);
  }

  Future<void> _loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://josephkiarie2.pythonanywhere.com/api/users/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.getToken()}',
        },
      );
      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body);
        final profile = data['profile'] ?? {};
        final prefs   = await SharedPreferences.getInstance();
        if (profile['profile_photo'] != null &&
            profile['profile_photo'].toString().isNotEmpty) {
          await prefs.setString('profilePhoto', profile['profile_photo']);
          AuthService.profilePhoto = profile['profile_photo'];
        }
        if (mounted) {
          setState(() {
            profilePhoto  = profile['profile_photo'];
            location      = profile['location'];
            bio           = profile['bio'];
            farmSize      = profile['farm_size']?.toString();
            averageRating = double.tryParse(
                profile['average_rating']?.toString() ?? '');
            totalRatings  = int.tryParse(
                profile['total_ratings']?.toString() ?? '');
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final role = AuthService.role ?? '';

      // Orders stats
      final ordRes = await ApiHelper.get('/orders/');
      if (ordRes.statusCode == 200) {
        final List raw = jsonDecode(ordRes.body) as List;
        int total = raw.length;
        int delivered = raw.where((o) => o['status'] == 'delivered').length;
        int pending   = raw
            .where((o) =>
                o['status'] == 'pending' ||
                o['status'] == 'pending_delivery')
            .length;
        double spent  = raw
            .where((o) =>
                o['status'] == 'paid' || o['status'] == 'delivered')
            .fold(0.0, (s, o) =>
                s + (double.tryParse(o['total_price']?.toString() ?? '0') ?? 0));
        if (mounted) {
          setState(() {
            _totalOrders    = total;
            _deliveredCount = delivered;
            _pendingCount   = pending;
            _totalSpent     = spent;
          });
        }
      }

      // Farmer product count
      if (role == 'farmer') {
        final dashRes = await ApiHelper.get('/dashboard/farmer/');
        if (dashRes.statusCode == 200) {
          final data = jsonDecode(dashRes.body) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _productCount = data['total_products_listed'] ?? 0;
            });
          }
        }
      }
    } catch (_) {}
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final username   = AuthService.username ?? 'User';
    final phone      = AuthService.phoneNumber ?? '';
    final role       = AuthService.role ?? '';
    final isFarmer   = role == 'farmer';
    final isAdmin    = role == 'admin';
    final isConsumer = !isFarmer && !isAdmin;

    String? fullImageUrl;
    if (profilePhoto != null && profilePhoto!.isNotEmpty) {
      fullImageUrl = profilePhoto!.startsWith('http')
          ? profilePhoto!
          : 'https://josephkiarie2.pythonanywhere.com$profilePhoto';
    }

    // Role accent colour
    final Color accent = isAdmin
        ? Colors.indigo
        : isFarmer
            ? Colors.green[800]!
            : Colors.teal[700]!;
    final Color accentLight = isAdmin
        ? Colors.indigo[400]!
        : isFarmer
            ? Colors.green[500]!
            : Colors.teal[400]!;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9F0),
        body: Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Hero SliverAppBar ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: accent,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: _loadAll,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit Profile',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileEditScreen(
                          currentUsername: AuthService.username ?? '',
                          currentBio:      bio ?? '',
                          currentLocation: location ?? '',
                          currentFarmSize: farmSize ?? '',
                          currentEmail:    '',
                        ),
                      ),
                    );
                    _loadAll();
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent, accentLight],
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(top: -50, right: -50,
                      child: _circle(200, Colors.white.withOpacity(0.07))),
                  Positioned(bottom: 30, left: -40,
                      child: _circle(160, Colors.white.withOpacity(0.05))),
                  Positioned(top: 80, right: 40,
                      child: _circle(60, Colors.white.withOpacity(0.08))),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            backgroundImage: fullImageUrl != null
                                ? NetworkImage(fullImageUrl) : null,
                            child: fullImageUrl == null
                                ? Text(
                                    username.isNotEmpty
                                        ? username[0].toUpperCase() : '?',
                                    style: GoogleFonts.poppins(
                                        fontSize: 36, color: Colors.white,
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(username,
                            style: GoogleFonts.poppins(
                                fontSize: 22, fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(phone,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings
                                  : isFarmer
                                      ? Icons.agriculture
                                      : Icons.person_rounded,
                              color: Colors.white, size: 13),
                            const SizedBox(width: 5),
                            Text(role.toUpperCase(),
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        // Farmer star rating
                        if (isFarmer &&
                            averageRating != null &&
                            averageRating! > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            ...List.generate(5, (i) => Icon(
                              i < averageRating!.floor()
                                  ? Icons.star_rounded
                                  : (i < averageRating!
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded),
                              color: Colors.amber, size: 16,
                            )),
                            const SizedBox(width: 6),
                            Text(
                              '${averageRating!.toStringAsFixed(1)} (${totalRatings ?? 0} reviews)',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 11)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Stats strip ──────────────────────────────────
                  _sectionPad(_statsStrip(isFarmer, isAdmin, accent)),

                  const SizedBox(height: 20),

                  // ── About card ────────────────────────────────────
                  if ((bio != null && bio!.isNotEmpty) ||
                      (location != null && location!.isNotEmpty) ||
                      (farmSize != null && farmSize!.isNotEmpty))
                    _sectionPad(_aboutCard(isFarmer, accent)),

                  if ((bio != null && bio!.isNotEmpty) ||
                      (location != null && location!.isNotEmpty) ||
                      (farmSize != null && farmSize!.isNotEmpty))
                    const SizedBox(height: 16),

                  // ── Quick actions grid ────────────────────────────
                  _sectionLabel('Quick Actions'),
                  const SizedBox(height: 12),
                  _sectionPad(
                      _quickActionsGrid(context, isFarmer, isAdmin, isConsumer, accent)),

                  const SizedBox(height: 20),

                  // ── Menu tiles ────────────────────────────────────
                  _sectionLabel('Account'),
                  const SizedBox(height: 12),
                  _sectionPad(_menuSection(
                      context, isFarmer, isAdmin, isConsumer, accent)),

                  const SizedBox(height: 24),

                  // ── Logout ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await AuthService.logout();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: Text('Logout',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats strip ────────────────────────────────────────────────
  Widget _statsStrip(bool isFarmer, bool isAdmin, Color accent) {
    final stats = isFarmer
        ? [
            _StatItem('📦', '$_productCount', 'Products'),
            _StatItem('🛒', '$_totalOrders', 'Orders'),
            _StatItem('✅', '$_deliveredCount', 'Delivered'),
            _StatItem('⭐', averageRating != null && averageRating! > 0
                ? averageRating!.toStringAsFixed(1) : '—', 'Rating'),
          ]
        : isAdmin
            ? [
                _StatItem('🛒', '$_totalOrders', 'Orders'),
                _StatItem('✅', '$_deliveredCount', 'Delivered'),
                _StatItem('⏳', '$_pendingCount', 'Pending'),
                _StatItem('💰', 'KSh ${_fmt(_totalSpent)}', 'Revenue'),
              ]
            : [
                _StatItem('🛒', '$_totalOrders', 'Orders'),
                _StatItem('✅', '$_deliveredCount', 'Delivered'),
                _StatItem('⏳', '$_pendingCount', 'Pending'),
                _StatItem('💰', 'KSh ${_fmt(_totalSpent)}', 'Spent'),
              ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: stats.map((s) {
          final isLast = stats.last == s;
          return Expanded(
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(s.value,
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.bold,
                          color: accent),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(s.label,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey[500]),
                      textAlign: TextAlign.center),
                ]),
              ),
              if (!isLast)
                Container(width: 1, height: 40, color: Colors.grey[200]),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── About card ─────────────────────────────────────────────────
  Widget _aboutCard(bool isFarmer, Color accent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.person_outline_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Text('About Me',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 15, color: accent)),
        ]),
        const SizedBox(height: 14),
        if (bio != null && bio!.isNotEmpty) ...[
          Text(bio!,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[700], height: 1.5)),
          const SizedBox(height: 10),
        ],
        if (location != null && location!.isNotEmpty)
          _aboutRow(Icons.location_on_outlined, location!, Colors.red[400]!),
        if (isFarmer && farmSize != null && farmSize!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _aboutRow(Icons.landscape_outlined,
              '$farmSize acres of farmland', Colors.green[600]!),
        ],
      ]),
    );
  }

  Widget _aboutRow(IconData icon, String text, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]))),
    ]);
  }

  // ── Quick actions grid ─────────────────────────────────────────
  Widget _quickActionsGrid(BuildContext context, bool isFarmer, bool isAdmin,
      bool isConsumer, Color accent) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'My Orders',
        color: Colors.orange,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OrdersScreen())),
      ),
      if (isFarmer)
        _QuickAction(
          icon: Icons.bar_chart_rounded,
          label: 'Dashboard',
          color: Colors.green[700]!,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FarmerDashboardScreen())),
        ),
      if (isConsumer)
        _QuickAction(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          color: Colors.teal[700]!,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const ConsumerDashboardScreen())),
        ),
      if (isAdmin)
        _QuickAction(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Admin Panel',
          color: Colors.indigo,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
        ),
      if (isFarmer)
        _QuickAction(
          icon: Icons.star_rounded,
          label: 'My Reviews',
          color: Colors.amber[700]!,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RatingsScreen())),
        ),
      if (isConsumer)
        _QuickAction(
          icon: Icons.rate_review_rounded,
          label: 'My Reviews',
          color: Colors.amber[700]!,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RatingsScreen())),
        ),
      _QuickAction(
        icon: Icons.edit_rounded,
        label: 'Edit Profile',
        color: Colors.blueGrey,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileEditScreen(
                currentUsername: AuthService.username ?? '',
                currentBio:      bio ?? '',
                currentLocation: location ?? '',
                currentFarmSize: farmSize ?? '',
                currentEmail:    '',
              ),
            ),
          );
          _loadAll();
        },
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: actions.map((a) => _quickActionTile(a)).toList(),
    );
  }

  Widget _quickActionTile(_QuickAction a) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        a.onTap();
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: a.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: a.color.withOpacity(0.2)),
          ),
          child: Icon(a.icon, color: a.color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(a.label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700],
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Menu tiles ─────────────────────────────────────────────────
  Widget _menuSection(BuildContext context, bool isFarmer, bool isAdmin,
      bool isConsumer, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        _menuTile(Icons.location_on_outlined, 'Delivery Location',
            location ?? 'Not set', Colors.blue, () {}),
        _divider(),
        _menuTile(Icons.payment_outlined, 'Payment Methods',
            'M-Pesa / Pay on Delivery', Colors.purple, () {}),
        _divider(),
        _menuTile(Icons.notifications_outlined, 'Notifications',
            'Manage alerts', Colors.orange, () {}),
        _divider(),
        _menuTile(Icons.security_outlined, 'Security',
            'Password & account', Colors.green[700]!, () {}),
        _divider(),
        _menuTile(Icons.help_outline_rounded, 'Help & Support',
            'FAQs & contact', Colors.teal, () {}),
        _divider(),
        _menuTile(Icons.settings_outlined, 'Settings',
            'App preferences', Colors.grey, () {}),
      ]),
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Colors.grey),
    );
  }

  Widget _divider() => Divider(
      height: 1, thickness: 1,
      indent: 56, endIndent: 16,
      color: Colors.grey[100]);

  // ── Helpers ───────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(label,
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: Colors.grey[500], letterSpacing: 0.5)),
  );

  Widget _sectionPad(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: child,
  );

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

// ── Data classes ─────────────────────────────────────────────────
class _StatItem {
  final String emoji, value, label;
  const _StatItem(this.emoji, this.value, this.label);
}

class _QuickAction {
  final IconData    icon;
  final String      label;
  final Color       color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });
}