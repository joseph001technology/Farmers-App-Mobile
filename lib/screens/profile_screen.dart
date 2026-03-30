import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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
        Uri.parse("https://josephkiarie2.pythonanywhere.com/api/users/profile/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AuthService.getToken()}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          profilePhoto = data['profile_photo'];
          location = data['location'];
          bio = data['bio'];
          farmSize = data['farm_size']?.toString();
          isLoading = false;
        });
      } else {
        print("Profile error: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error loading profile: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = AuthService.username ?? "User";
    final phone = AuthService.phoneNumber ?? "";
    final role = AuthService.role ?? "";

    // Fix for relative image URL
    final fullImageUrl = (profilePhoto != null && profilePhoto!.isNotEmpty)
        ? "https://josephkiarie2.pythonanywhere.com$profilePhoto"
        : null;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Image
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green[200],
              backgroundImage:
                  fullImageUrl != null ? NetworkImage(fullImageUrl) : null,
              child: fullImageUrl == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),

            const SizedBox(height: 12),

            Text(
              username,
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(
              phone,
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),

            const SizedBox(height: 4),

            // Role badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role.toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 20),

            // Extra profile details
            if (location != null && location!.isNotEmpty)
              Text("📍 $location",
                  style: GoogleFonts.poppins(color: Colors.grey[700])),

            if (bio != null && bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  bio!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(),
                ),
              ),

            if (farmSize != null && farmSize!.isNotEmpty)
              Text("🌾 Farm Size: $farmSize acres",
                  style: GoogleFonts.poppins()),

            const SizedBox(height: 20),

            // EDIT PROFILE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.edit, color: Colors.green),
                  title: Text("Edit Profile",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  subtitle: const Text("Update your information and photo"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileEditScreen()),
                    );
                    loadProfile(); // 🔥 refresh after editing
                  },
                ),
              ),
            ),

            // OTHER TILES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTile(
                    Icons.shopping_bag,
                    "My Orders",
                    "View your past orders",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    ),
                  ),
                  _buildTile(
                    Icons.location_on,
                    "Delivery Location",
                    location ?? "Not set",
                    onTap: () {},
                  ),
                  _buildTile(
                    Icons.payment,
                    "Payment Methods",
                    "M-Pesa / Card (coming soon)",
                    onTap: () {},
                  ),
                  _buildTile(
                    Icons.settings,
                    "Settings",
                    "App preferences",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // LOGOUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AuthService.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
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

  Widget _buildTile(IconData icon, String title, String subtitle,
      {required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}