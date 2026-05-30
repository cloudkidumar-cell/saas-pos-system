import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      //'https://saas-pos-system-production.up.railway.app';
      'https://saas-pos-system-production-6139.up.railway.app';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('tenant_id');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ================================
  // AUTH
  // ================================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      final token = data['data']['token'];
      final user = data['data']['user'];

      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user));

      // Save tenant_id dari user object
      String tenantId = user['tenant_id']?.toString() ?? '';

      // Kalau takde dalam user, decode dari JWT
      if (tenantId.isEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final jwtData = jsonDecode(decoded) as Map<String, dynamic>;
            tenantId = jwtData['tenant_id']?.toString() ?? '';
          }
        } catch (e) {
          debugPrint('JWT decode error: $e');
        }
      }

      await prefs.setString('tenant_id', tenantId);
      debugPrint('Login saved tenant_id: $tenantId');

      return data;
    } else {
      throw Exception(data['message']);
    }
  }

  static Future<Map<String, dynamic>> register({
    required String namaKedai,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nama_kedai': namaKedai,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data['data'];
    } else {
      throw Exception(data['message']);
    }
  }

  // ================================
  // PRODUCTS
  // ================================

  static Future<List<dynamic>> getProducts() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['message']);
    }
  }

  static Future<Map<String, dynamic>> getProductByBarcode(
    String barcode,
  ) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/products/barcode/$barcode'),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['message']);
    }
  }

  static Future<void> restockProduct(String id, int quantity) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id/restock'),
      headers: headers,
      body: jsonEncode({'quantity': quantity}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message']);
    }
  }

  // ================================
  // LIBRARY
  // ================================

  static Future<List<dynamic>> searchLibrary(String query) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/library?search=$query'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getLibraryByBarcode(
    String barcode,
  ) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/library/barcode/$barcode'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    }
    return null;
  }

  static Future<bool> addFromLibrary({
    required String libraryId,
    required String tenantId,
    required double harga,
    int stok = 0,
  }) async {
    final headers = await getHeaders();
    final body = jsonEncode({
      'library_id': libraryId,
      'tenant_id': tenantId,
      'harga': harga,
      'stok': stok,
    });

    debugPrint('addFromLibrary body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/library/add-to-tenant'),
      headers: headers,
      body: body,
    );

    debugPrint('addFromLibrary status: ${response.statusCode}');
    debugPrint('addFromLibrary response: ${response.body}');

    return response.statusCode == 201;
  }

  // ================================
  // SALES
  // ================================

  static Future<Map<String, dynamic>> createSale(
    List<Map<String, dynamic>> items, {
    String? paymentMethod,
    double? cashReceived,
    double? change,
  }) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/sales'),
      headers: headers,
      body: jsonEncode({
        'items': items,
        'payment_method': paymentMethod,
        'cash_received': cashReceived,
        'change': change,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data['data'];
    } else {
      throw Exception(data['message']);
    }
  }

  static Future<List<dynamic>> getSalesByDate(String date) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/sales?date=$date'),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['message']);
    }
  }

  // ================================
  // STAFF
  // ================================

  static Future<List<dynamic>> getStaff() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/staff'),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['message']);
    }
  }

  static Future<Map<String, dynamic>> addStaff(
    String email,
    String password,
  ) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/staff'),
      headers: headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data['data'];
    } else {
      throw Exception(data['message']);
    }
  }

  static Future<void> suspendStaff(String id) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/staff/$id/suspend'),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message']);
    }
  }

  static Future<void> deleteStaff(String id) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/staff/$id'),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message']);
    }
  }

  // ================================
  // EOD
  // ================================

  static Future<Map<String, dynamic>> getEOD() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/sales/eod'),
      headers: headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['message']);
    }
  }

  // ================================
  // UTILS
  // ================================

  static DateTime parseDateTime(String dateStr) {
    if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
      dateStr = '${dateStr}Z';
    }
    return DateTime.parse(dateStr).toLocal();
  }

  static const String supabaseUrl = 'https://bwninrdadepztbyhmfbs.supabase.co';
  //'https://gpmmgfibmbmfyvnmmdge.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_5Ve90Gmg5AOdl2PN5PzGug_GuMqwzPM';
}
