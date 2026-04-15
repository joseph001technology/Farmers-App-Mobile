import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String? profilePhoto;
  String? location;
  String? bio;
  String? farmSize;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://josephkiarie2.pythonanywhere.com/api/users/profile/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AuthService.getToken()}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = data['profile'] ?? {};

        final prefs = await SharedPreferences.getInstance();
        if (profile['profile_photo'] != null &&
            profile['profile_photo'].toString().isNotEmpty) {
          await prefs.setString('profilePhoto', profile['profile_photo']);
          AuthService.profilePhoto = profile['profile_photo'];
        }

        setState(() {
          profilePhoto = profile['profile_photo'];
          location = profile['location'];
          bio = profile['bio'];
          farmSize = profile['farm_size']?.toString();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = AuthService.username ?? "User";
    final phone = AuthService.phoneNumber ?? "";
    final role = AuthService.role ?? "";

    String? fullImageUrl;
    if (profilePhoto != null && profilePhoto!.isNotEmpty) {
      fullImageUrl = profilePhoto!.startsWith('http')
          ? profilePhoto!
          : 'https://josephkiarie2.pythonanywhere.com$profilePhoto';
    }

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔥 Green gradient header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[800]!, Colors.green[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    children: [
                      // Edit button top right
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileEditScreen(
                                  currentUsername: AuthService.username ?? '',
                                  currentBio: bio ?? '',
                                  currentLocation: location ?? '',
                                  currentFarmSize: farmSize ?? '',
                                  currentEmail: '',
                                ),
                              ),
                            );
                            loadProfile();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text("Edit",
                                    style: GoogleFonts.poppins(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Profile photo
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.green[300],
                              backgroundImage: fullImageUrl != null
                                  ? NetworkImage(fullImageUrl)
                                  : null,
                              child: fullImageUrl == null
                                  ? const Icon(Icons.person,
                                      size: 60, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        username,
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        phone,
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 13),
                      ),

                      const SizedBox(height: 8),

                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 Bio/location/farmsize card
            if ((bio != null && bio!.isNotEmpty) ||
                (location != null && location!.isNotEmpty) ||
                (farmSize != null && farmSize!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("About",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.green[800])),
                      const SizedBox(height: 10),
                      if (location != null && location!.isNotEmpty)
                        _infoRow("📍", location!),
                      if (farmSize != null && farmSize!.isNotEmpty)
                        _infoRow("🌾", "Farm Size: $farmSize acres"),
                      if (bio != null && bio!.isNotEmpty)
                        _infoRow("💬", bio!),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 🔥 Quick stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statCard("🛒", "Orders", "View all"),
                  const SizedBox(width: 10),
                  _statCard("📍", "Location", location ?? "Not set"),
                  const SizedBox(width: 10),
                  _statCard("🌾", "Farm", "${farmSize ?? '?'} acres"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 Menu tiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTile(
                    Icons.shopping_bag_outlined,
                    "My Orders",
                    "View your past orders",
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrdersScreen()),
                    ),
                  ),
                  _buildTile(
                    Icons.location_on_outlined,
                    "Delivery Location",
                    location ?? "Not set",
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  _buildTile(
                    Icons.payment_outlined,
                    "Payment Methods",
                    "M-Pesa / Card (coming soon)",
                    color: Colors.purple,
                    onTap: () {},
                  ),
                  _buildTile(
                    Icons.settings_outlined,
                    "Settings",
                    "App preferences",
                    color: Colors.grey,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: Text("Logout",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.grey[500]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle,
      {required VoidCallback onTap, Color color = Colors.green}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}