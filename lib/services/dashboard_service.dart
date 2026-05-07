import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ← needed for MediaType
import '../helpers/api_helper.dart';
import '../models/dashboard.dart';

class DashboardService {
  static const _base = 'https://josephkiarie2.pythonanywhere.com/api';

  // ── Farmer dashboard stats ────────────────────────────────────────
  static Future<FarmerDashboard> getFarmerDashboard() async {
    final res = await ApiHelper.get('/dashboard/farmer/');
    if (res.statusCode == 200) {
      return FarmerDashboard.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw 'Dashboard unavailable (${res.statusCode})';
  }

  // ── Admin dashboard ───────────────────────────────────────────────
  static Future<AdminDashboard> getAdminDashboard() async {
    final res = await ApiHelper.get('/dashboard/admin/');
    if (res.statusCode == 200) {
      return AdminDashboard.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw 'Dashboard unavailable (${res.statusCode})';
  }

  // ── Load only THIS farmer's products ─────────────────────────────
  static Future<List<Map<String, dynamic>>> getMyProducts() async {
    // 1. Try farmer dashboard — it includes products list
    try {
      final res = await ApiHelper.get('/dashboard/farmer/');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final products = data['products'] ?? data['my_products'];
        if (products is List && products.isNotEmpty) {
          return products.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}

    // 2. Try ?mine=true filter
    try {
      final res = await ApiHelper.get('/products/?mine=true');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['results'] ?? []);
        if ((list as List).isNotEmpty) {
          return list.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}

    // 3. Try /products/mine/ endpoint
    try {
      final res = await ApiHelper.get('/products/mine/');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['results'] ?? []);
        if ((list as List).isNotEmpty) {
          return list.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}

    // 4. Fallback: fetch all and filter client-side
    try {
      final meRes = await ApiHelper.get('/users/profile/');
      String? myUsername, myPhone;
      if (meRes.statusCode == 200) {
        final me = jsonDecode(meRes.body) as Map<String, dynamic>;
        myUsername = me['username']?.toString();
        myPhone    = me['phone_number']?.toString();
      }

      final res = await ApiHelper.get('/products/');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is List ? data : (data['results'] ?? [])) as List;
        if (myUsername == null && myPhone == null) {
          return list.cast<Map<String, dynamic>>();
        }
        return list
            .cast<Map<String, dynamic>>()
            .where((p) {
              final farmer = p['farmer']?.toString() ?? '';
              if (myUsername != null && farmer.contains(myUsername)) return true;
              if (myPhone    != null && farmer.contains(myPhone))    return true;
              return false;
            })
            .toList();
      }
    } catch (_) {}

    return [];
  }

  // ── Update stock (quantity) ───────────────────────────────────────
  static Future<bool> updateStock(int productId, int newQty) async {
    final body = {'quantity': newQty};

    for (final path in ['/products/$productId/', '/products/$productId']) {
      try {
        final res = await ApiHelper.patch(path, body);
        if (res.statusCode == 200 || res.statusCode == 204) return true;
      } catch (_) {}
    }

    for (final path in ['/products/$productId/', '/products/$productId']) {
      try {
        final res = await ApiHelper.put(path, body);
        if (res.statusCode == 200 || res.statusCode == 204) return true;
      } catch (_) {}
    }

    return false;
  }

  // ── Add product with optional image (multipart) ───────────────────
  // Django ImageField REQUIRES multipart/form-data — NOT JSON.
  // The serializer's `image` field must be writable (see backend note below).
  static Future<Map<String, dynamic>> addProduct(
    Map<String, dynamic> fields, {
    File? imageFile,
  }) async {
    final token = await ApiHelper.getToken();

    final uri = Uri.parse('$_base/products/');
    final req = http.MultipartRequest('POST', uri);

    // Auth header — do NOT set Content-Type manually for multipart;
    // http package sets it automatically with the correct boundary.
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    // ── Text fields ──────────────────────────────────────────────────
    // Only send fields the serializer actually accepts as writable.
    // 'unit' is not in the model so we skip it.
    final allowedFields = ['name', 'price', 'description', 'quantity', 'category', 'harvest_date'];
    fields.forEach((k, v) {
      if (v != null && allowedFields.contains(k)) {
        req.fields[k] = v.toString();
      }
    });

    // ── Image attachment ─────────────────────────────────────────────
    if (imageFile != null && await imageFile.exists()) {
      final ext  = imageFile.path.split('.').last.toLowerCase();

      // Map extension → MIME type
      final mimeType = switch (ext) {
        'png'  => MediaType('image', 'png'),
        'gif'  => MediaType('image', 'gif'),
        'webp' => MediaType('image', 'webp'),
        _      => MediaType('image', 'jpeg'), // jpg / jpeg / heic fallback
      };

      req.files.add(await http.MultipartFile.fromPath(
        'image',            // ← must match Django model field name exactly
        imageFile.path,
        contentType: mimeType, // ← THIS is what was missing before
      ));
    }

    // ── Send & handle response ───────────────────────────────────────
    final streamed = await req.send();
    final res      = await http.Response.fromStream(streamed);

    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    // Parse backend validation errors into a readable message
    String errMsg = 'Failed to add product (${res.statusCode})';
    try {
      final data = jsonDecode(res.body);
      if (data is Map) {
        final msgs = <String>[];
        data.forEach((k, v) {
          if (v is List) msgs.add('$k: ${v.join(', ')}');
          else msgs.add('$k: $v');
        });
        if (msgs.isNotEmpty) errMsg = msgs.join('\n');
      }
    } catch (_) {}
    throw errMsg;
  }

  // ── Farmer orders ─────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getFarmerOrders() async {
    final res = await ApiHelper.get('/orders/');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}