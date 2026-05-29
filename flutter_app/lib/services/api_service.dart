import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Guna IP MacBook ko — bukan localhost
  // Flutter simulator tak boleh access localhost
  //static const String baseUrl = 'http://192.168.0.64:3000';
  static const String baseUrl =
      'https://saas-pos-system-production.up.railway.app';

  // Get token dari storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Remove token
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // Headers dengan token
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LOGIN
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
      // Save token dan user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['data']['token']);
      await prefs.setString('user', jsonEncode(data['data']['user']));
      return data;
    } else {
      throw Exception(data['message']);
    }
  }

  // GET PRODUCTS
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

  // GET PRODUCT BY BARCODE
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

  // GET STAFF
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

  // GET EOD
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

  // ADD CASHIER
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

  // SUSPEND CASHIER
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

  // DELETE CASHIER
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

  // CREATE SALE
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

  // GET SALES BY DATE
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

  // REGISTER TENANT
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

  // RESTOCK PRODUCT
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

  // Helper — parse UTC datetime dari database
  static DateTime parseDateTime(String dateStr) {
    // Tambah Z kalau takde — supaya Flutter tahu ini UTC
    if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
      dateStr = '${dateStr}Z';
    }
    return DateTime.parse(dateStr).toLocal();
  }

  static const String supabaseUrl = 'https://gpmmgfibmbmfyvnmmdge.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_gBgZoL-aD07KZAP8WWnDlQ_bfgzv0j-';
}
