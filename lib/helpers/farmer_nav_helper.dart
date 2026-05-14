import 'package:flutter/material.dart';
import '../services/farmer_service.dart';
import '../screens/farmer_profile_screen.dart';

/// Navigates to FarmerProfileScreen.
/// Resolves farmerId from name cache when not directly available.
Future<void> goToFarmerProfile(
  BuildContext context, {
  int?    farmerId,
  required String farmerName,
  String? farmerLocation,
}) async {
  int? resolvedId = (farmerId != null && farmerId > 0) ? farmerId : null;

  resolvedId ??= FarmerService.getIdForName(farmerName);

  if (resolvedId == null || resolvedId < 0) {
    // Warm the cache by fetching products, then retry
    final profile = await FarmerService.getFarmerProfileByName(farmerName);
    resolvedId = (profile != null && profile.id > 0) ? profile.id : null;
  }

  if (!context.mounted) return;

  if (resolvedId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Profile not found for $farmerName'),
      behavior: SnackBarBehavior.floating,
    ));
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FarmerProfileScreen(
        farmerId:       resolvedId!,
        farmerName:     farmerName,
        farmerLocation: farmerLocation,
      ),
    ),
  );
}