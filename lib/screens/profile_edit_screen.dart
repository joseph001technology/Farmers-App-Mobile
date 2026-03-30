import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  String username = '';
  String email = '';
  String bio = '';
  String location = '';
  String farmSize = '';
  File? selectedImage;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // Optional: You can fetch latest profile here if you want
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('https://josephkiarie2.pythonanywhere.com/api/users/profile/'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['username'] = username;
      request.fields['email'] = email;
      request.fields['bio'] = bio;
      request.fields['location'] = location;
      if (farmSize.isNotEmpty) request.fields['farm_size'] = farmSize;

      if (selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('profile_photo', selectedImage!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context); // Go back to profile screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
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
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: selectedImage != null ? FileImage(selectedImage!) : null,
                    child: selectedImage == null ? const Icon(Icons.camera_alt, size: 40) : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                decoration: const InputDecoration(labelText: "Username"),
                initialValue: username,
                onChanged: (v) => username = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                initialValue: email,
                onChanged: (v) => email = v,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Bio"),
                initialValue: bio,
                onChanged: (v) => bio = v,
                maxLines: 3,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Location"),
                initialValue: location,
                onChanged: (v) => location = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Farm Size (acres)"),
                initialValue: farmSize,
                onChanged: (v) => farmSize = v,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green[700],
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}