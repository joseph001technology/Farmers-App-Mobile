import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final String currentUsername;
  final String currentEmail;
  final String currentBio;
  final String currentLocation;
  final String currentFarmSize;

  const ProfileEditScreen({
    super.key,
    this.currentUsername = '',
    this.currentEmail = '',
    this.currentBio = '',
    this.currentLocation = '',
    this.currentFarmSize = '',
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _farmSizeController;

  File? selectedImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _emailController = TextEditingController(text: widget.currentEmail);
    _bioController = TextEditingController(text: widget.currentBio);
    _locationController = TextEditingController(text: widget.currentLocation);
    _farmSizeController = TextEditingController(text: widget.currentFarmSize);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final token = AuthService.getToken();

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            'https://josephkiarie2.pythonanywhere.com/api/users/profile/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['username'] = _usernameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['bio'] = _bioController.text;
      request.fields['location'] = _locationController.text;
      if (_farmSizeController.text.isNotEmpty) {
        request.fields['farm_size'] = _farmSizeController.text;
      }

      if (selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'profile_photo', selectedImage!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Update AuthService with new username
        AuthService.username = _usernameController.text;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated! ✅")),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text("Edit Profile",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Profile Photo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.green[200],
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : null,
                        child: selectedImage == null
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Center(
                child: Text("Tap to change photo",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600])),
              ),

              const SizedBox(height: 24),

              _buildField("Username", _usernameController,
                  icon: Icons.person_outline),
              const SizedBox(height: 12),
              _buildField("Email", _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildField("Bio", _bioController,
                  icon: Icons.info_outline, maxLines: 3),
              const SizedBox(height: 12),
              _buildField("Location", _locationController,
                  icon: Icons.location_on_outlined),
              const SizedBox(height: 12),
              _buildField("Farm Size (acres)", _farmSizeController,
                  icon: Icons.agriculture_outlined,
                  keyboardType: TextInputType.number),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _updateProfile,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isLoading ? "Saving..." : "Save Changes",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.green) : null,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
      ),
    );
  }
}