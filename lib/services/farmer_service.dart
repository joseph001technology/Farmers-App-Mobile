import 'dart:convert';
import '../helpers/api_helper.dart';

class FarmerProfile {
  final int     id;
  final String  username;
  final String? phoneNumber;
  final String? email;
  final String? role;
  final String? profilePhoto;
  final String? bio;
  final String? location;
  final double? farmSize;

  const FarmerProfile({
    required this.id,
    required this.username,
    this.phoneNumber,
    this.email,
    this.role,
    this.profilePhoto,
    this.bio,
    this.location,
    this.farmSize,
  });

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    return FarmerProfile(
      id:           (json['id'] as num).toInt(),
      username:     json['username']?.toString() ?? '',
      phoneNumber:  json['phone_number']?.toString(),
      email:        json['email']?.toString(),
      role:         json['role']?.toString(),
      profilePhoto: profile['profile_photo']?.toString(),
      bio:          profile['bio']?.toString(),
      location:     profile['location']?.toString(),
      farmSize:     double.tryParse(profile['farm_size']?.toString() ?? ''),
    );
  }
}

class FarmerService {
  static final _cacheById   = <int, FarmerProfile>{};
  static final _cacheByName = <String, FarmerProfile>{};
  static bool _listPopulated = false;

  // ── Public API ────────────────────────────────────────────────────

  /// Fetch a farmer profile by ID.
  /// Tries GET /api/users/farmer/<id>/ first (new endpoint),
  /// then falls back to the products-list cache.
  static Future<FarmerProfile?> getFarmerProfile(int farmerId) async {
    if (farmerId <= 0) return null;
    if (_cacheById.containsKey(farmerId)) return _cacheById[farmerId];

    // 1️⃣ Direct endpoint (fast, accurate)
    try {
      final res = await ApiHelper.get('/users/farmer/$farmerId/');
      if (res.statusCode == 200) {
        final profile = FarmerProfile.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
        _cacheById[profile.id] = profile;
        _cacheByName[profile.username.toLowerCase()] = profile;
        return profile;
      }
    } catch (_) {}

    // 2️⃣ Fallback: products-list cache
    await _populateCacheFromProducts();
    return _cacheById[farmerId];
  }

  /// Fetch a farmer profile by username (when ID is not available).
  static Future<FarmerProfile?> getFarmerProfileByName(String name) async {
    if (name.isEmpty) return null;
    final key = name.trim().toLowerCase();
    if (_cacheByName.containsKey(key)) return _cacheByName[key];
    await _populateCacheFromProducts();
    return _cacheByName[key];
  }

  /// Synchronous ID lookup from cache (call after cache is warm).
  static int? getIdForName(String name) =>
      _cacheByName[name.trim().toLowerCase()]?.id;

  /// Pre-warm the cache — call this on app start or home screen load.
  static Future<void> preWarm() => _populateCacheFromProducts();

  static void clearCache() {
    _cacheById.clear();
    _cacheByName.clear();
    _listPopulated = false;
  }

  // ── Internal ──────────────────────────────────────────────────────

  /// Scans /api/users/farmers/ for a full list, then falls back to
  /// /api/products/ to extract farmer info from product records.
  static Future<void> _populateCacheFromProducts() async {
    if (_listPopulated) return;
    _listPopulated = true;

    // 1️⃣ Try the new farmers list endpoint first
    try {
      final res = await ApiHelper.get('/users/farmers/');
      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body) as List;
        for (final f in raw.cast<Map<String, dynamic>>()) {
          final profile = FarmerProfile.fromJson(f);
          if (profile.id > 0) {
            _cacheById[profile.id] = profile;
            _cacheByName[profile.username.toLowerCase()] = profile;
          }
        }
        return; // success — no need to scan products
      }
    } catch (_) {}

    // 2️⃣ Fallback: extract farmer info from products list
    try {
      final res = await ApiHelper.get('/products/');
      if (res.statusCode != 200) { _listPopulated = false; return; }

      final List raw = jsonDecode(res.body) as List;
      for (final p in raw.cast<Map<String, dynamic>>()) {
        // Resolve farmer ID
        int? fId = (p['farmer_id'] as num?)?.toInt();
        fId ??= p['farmer'] is int ? (p['farmer'] as int) : null;
        fId ??= p['farmer'] is Map
            ? ((p['farmer'] as Map)['id'] as num?)?.toInt()
            : null;

        // Resolve farmer name
        String? fName = p['farmer_name']?.toString()
            ?? p['farmer_username']?.toString();
        if ((fName == null || fName.isEmpty) && p['farmer'] is String) {
          final s = p['farmer'] as String;
          final m = RegExp(r'^(.*?)\s*\((\d+)\)\s*$').firstMatch(s);
          fName = m != null ? m.group(1)?.trim() : s.trim();
        }
        if ((fName == null || fName.isEmpty) && p['farmer'] is Map) {
          final fm = p['farmer'] as Map;
          fName = fm['username']?.toString() ?? fm['name']?.toString();
        }
        if (fName == null || fName.isEmpty) continue;

        // Resolve farmer photo
        String? fPhoto;
        if (p['farmer'] is Map) {
          final fm = p['farmer'] as Map;
          final prof = fm['profile'];
          if (prof is Map) fPhoto = prof['profile_photo']?.toString();
          fPhoto ??= fm['profile_photo']?.toString();
        }
        fPhoto ??= p['farmer_photo']?.toString()
            ?? p['farmer_profile_photo']?.toString()
            ?? p['farmer_image']?.toString();

        final fLoc = p['farmer_location']?.toString();

        if (fId != null && fId > 0) {
          if (!_cacheById.containsKey(fId)) {
            final profile = FarmerProfile(
              id: fId, username: fName,
              profilePhoto: fPhoto, location: fLoc,
            );
            _cacheById[fId] = profile;
            _cacheByName[fName.toLowerCase()] = profile;
          }
        } else {
          // No ID — still cache by name so photo loads
          if (!_cacheByName.containsKey(fName.toLowerCase())) {
            _cacheByName[fName.toLowerCase()] = FarmerProfile(
              id: -1, username: fName,
              profilePhoto: fPhoto, location: fLoc,
            );
          }
        }
      }
    } catch (_) {
      _listPopulated = false;
    }
  }
}