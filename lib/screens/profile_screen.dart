import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final username = AuthService.username ?? "User";
    final phone = AuthService.phoneNumber ?? "";
    final role = AuthService.role ?? "";

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

            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green[200],
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 12),

            // Name from AuthService
            Text(
              username,
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            // Phone from AuthService
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

            // Info tiles
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
                      MaterialPageRoute(
                          builder: (_) => const OrdersScreen()),
                    ),
                  ),
                  _buildTile(
                    Icons.location_on,
                    "Delivery Location",
                    "Nairobi, Kenya",
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

            // Logout
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
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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