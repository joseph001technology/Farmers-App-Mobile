import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../main.dart'; // so we can go to MainFarmScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String phone = '';
  String password = '';
  bool _isLoading = false;
  PhoneNumber number = PhoneNumber(isoCode: 'KE');

  void _fakeLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      // Fake success → go to main app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainFarmScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/farm_logo.png', height: 100), // ← add later
                const SizedBox(height: 40),
                Text(
                  "Welcome back to FreshFarm",
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Login with your phone number",
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Phone field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber num) {
                      number = num;
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      setSelectorButtonAsPrefixIcon: true,
                    ),
                    initialValue: number,
                    textFieldController: TextEditingController(),
                    formatInput: true,
                    keyboardType: TextInputType.phone,
                    inputDecoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      hintText: "712 345 678",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password field (we'll keep simple password for now – no OTP yet)
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (val) => val!.length < 6 ? "Too short" : null,
                  onChanged: (val) => password = val,
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _isLoading ? null : _fakeLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("New here? ", style: GoogleFonts.poppins(color: Colors.grey[700])),
                    TextButton(
                      onPressed: () {
                        // TODO: go to register screen later
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Register coming soon!")),
                        );
                      },
                      child: const Text("Create account"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}