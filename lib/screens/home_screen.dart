import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🌾 FreshFarm", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: const [Icon(Icons.notifications, color: Colors.green)],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Farm Image (we'll add real photo later)
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/farm_banner.png'), // put any farm photo here
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Joseph's Organic Farm\nNairobi • Kenya",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Welcome Text - This is what you asked for
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "🌱 Welcome to FreshFarm!\n\n"
                "Hi, I'm Joseph, a proud farmer in Nairobi growing fresh organic vegetables, fruits, eggs, and milk every day.\n\n"
                "Everything you see here is harvested today and delivered straight from my farm to your kitchen.\n\n"
                "No middlemen. Just pure goodness from the soil to your table ❤️",
                style: GoogleFonts.poppins(fontSize: 16, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 30),

            // Quick buttons (makes it feel amazing already)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text("Browse Products"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone),
                    label: const Text("Call Joseph"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Footer feel
            const Text("🚜 Scroll down to see today's harvest →", style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}