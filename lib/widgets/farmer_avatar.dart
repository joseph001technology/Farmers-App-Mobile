import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/farmer_service.dart';

/// A circle avatar that loads the farmer's profile photo from the backend.
/// Falls back to initials if no photo is available.
/// Supports lookup by ID or by name.
class FarmerAvatar extends StatefulWidget {
  final int?    farmerId;
  final String  farmerName;
  final double  radius;
  final Color?  backgroundColor;
  final Color?  textColor;
  final VoidCallback? onTap;

  const FarmerAvatar({
    super.key,
    this.farmerId,
    required this.farmerName,
    this.radius = 22,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  State<FarmerAvatar> createState() => _FarmerAvatarState();
}

class _FarmerAvatarState extends State<FarmerAvatar> {
  String? _photoUrl;
  bool    _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchPhoto();
  }

  @override
  void didUpdateWidget(FarmerAvatar old) {
    super.didUpdateWidget(old);
    if (old.farmerId != widget.farmerId ||
        old.farmerName != widget.farmerName) {
      _fetchPhoto();
    }
  }

  Future<void> _fetchPhoto() async {
    try {
      FarmerProfile? profile;
      if (widget.farmerId != null && widget.farmerId! > 0) {
        profile = await FarmerService.getFarmerProfile(widget.farmerId!);
      }
      // Fallback: lookup by name
      profile ??= await FarmerService.getFarmerProfileByName(widget.farmerName);
      if (mounted) {
        setState(() {
          _photoUrl = profile?.profilePhoto;
          _loaded   = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.farmerName.isNotEmpty
        ? widget.farmerName[0].toUpperCase()
        : '?';
    final bg   = widget.backgroundColor ?? Colors.green[100]!;
    final text = widget.textColor       ?? Colors.green[800]!;

    Widget avatar;
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundImage: NetworkImage(_photoUrl!),
        backgroundColor: bg,
        onBackgroundImageError: (_, _) {},
      );
    } else {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundColor: bg,
        child: !_loaded
            ? SizedBox(
                width: widget.radius * 0.6,
                height: widget.radius * 0.6,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: text),
              )
            : Text(initials,
                style: GoogleFonts.poppins(
                    fontSize: widget.radius * 0.65,
                    fontWeight: FontWeight.bold,
                    color: text)),
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(onTap: widget.onTap, child: avatar);
    }
    return avatar;
  }
}