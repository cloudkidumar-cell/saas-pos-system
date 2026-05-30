import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _products = [];
  bool _loading = true;
  late TabController _tabController;
  String _tenantId = '';

  List<dynamic> _libraryResults = [];
  bool _librarySearching = false;
  final _librarySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _librarySearchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    debugPrint('=== INIT DEBUG ===');

    // Cuba semua keys
    final allKeys = prefs.getKeys();
    debugPrint('All prefs keys: $allKeys');

    String tenantId = prefs.getString('tenant_id') ?? '';
    debugPrint('tenant_id from prefs: $tenantId');

    final userStr = prefs.getString('user');
    debugPrint('user string: $userStr');

    if (tenantId.isEmpty && userStr != null) {
      try {
        final user = jsonDecode(userStr) as Map<String, dynamic>;
        debugPrint('user keys: ${user.keys.toList()}');
        tenantId = user['tenant_id']?.toString() ?? '';
        debugPrint('tenant_id from user obj: $tenantId');
        if (tenantId.isNotEmpty) {
          await prefs.setString('tenant_id', tenantId);
        }
      } catch (e) {
        debugPrint('Parse user error: $e');
      }
    }

    // Last resort — ambil dari token JWT
    if (tenantId.isEmpty) {
      final token = prefs.getString('token');
      debugPrint('token: $token');
      if (token != null) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final data = jsonDecode(decoded) as Map<String, dynamic>;
            debugPrint('JWT payload: $data');
            tenantId = data['tenant_id']?.toString() ?? '';
            debugPrint('tenant_id from JWT: $tenantId');
            if (tenantId.isNotEmpty) {
              await prefs.setString('tenant_id', tenantId);
            }
          }
        } catch (e) {
          debugPrint('JWT decode error: $e');
        }
      }
    }

    debugPrint('Final tenant_id: $tenantId');
    setState(() => _tenantId = tenantId);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _loading = true);
      final data = await ApiService.getProducts();
      setState(() => _products = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _searchLibrary(String query) async {
    if (query.length < 2) {
      setState(() => _libraryResults = []);
      return;
    }
    setState(() => _librarySearching = true);
    try {
      final results = await ApiService.searchLibrary(query);
      debugPrint('Library results: ${results.length}');
      setState(() => _libraryResults = results);
    } catch (e) {
      debugPrint('Search library error: $e');
    } finally {
      setState(() => _librarySearching = false);
    }
  }

  Future<void> _showAddFromLibrary(Map<String, dynamic> libraryProduct) async {
    final hargaController = TextEditingController();
    final stokController = TextEditingController(text: '0');

    // Refresh tenant_id
    String tenantId = _tenantId;
    if (tenantId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      tenantId = prefs.getString('tenant_id') ?? '';

      if (tenantId.isEmpty) {
        final token = prefs.getString('token');
        if (token != null) {
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalized = base64Url.normalize(payload);
              final decoded = utf8.decode(base64Url.decode(normalized));
              final data = jsonDecode(decoded) as Map<String, dynamic>;
              tenantId = data['tenant_id']?.toString() ?? '';
            }
          } catch (e) {
            debugPrint('JWT decode error: $e');
          }
        }
      }
    }

    debugPrint('tenant_id for add: $tenantId');
    debugPrint('library_id: ${libraryProduct['id']}');

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          libraryProduct['nama'] ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                            fontSize: 14,
                          ),
                        ),
                        if (libraryProduct['brand'] != null)
                          Text(
                            libraryProduct['brand'],
                            style: const TextStyle(
                              color: AppColors.subtext,
                              fontSize: 12,
                            ),
                          ),
                        if (libraryProduct['barcode'] != null)
                          Text(
                            libraryProduct['barcode'],
                            style: const TextStyle(
                              color: AppColors.subtext,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (libraryProduct['kategori'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        libraryProduct['kategori'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Tetapkan Harga & Stok',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: hargaController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Harga (RM)',
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stok Awal',
                hintText: '0',
                prefixIcon: Icon(Icons.inventory_outlined),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final harga = double.tryParse(hargaController.text.trim());
                  if (harga == null || harga <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sila masukkan harga'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  if (tenantId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Sila logout dan login semula'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  final success = await ApiService.addFromLibrary(
                    libraryId: libraryProduct['id'],
                    tenantId: tenantId,
                    harga: harga,
                    stok: int.tryParse(stokController.text) ?? 0,
                  );

                  debugPrint('addFromLibrary result: $success');

                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  if (success) {
                    _loadProducts();
                    _librarySearchController.clear();
                    setState(() => _libraryResults = []);
                    _tabController.animateTo(0);
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Produk berjaya ditambah!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Produk sudah ada atau error'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Tambah ke Kedai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRestock(Map<String, dynamic> product) async {
    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restock — ${product['nama']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stok semasa: ${product['stok']}',
              style: const TextStyle(color: AppColors.subtext, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tambah Stok',
                hintText: '0',
                prefixIcon: Icon(Icons.add_box_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final qty = int.tryParse(controller.text.trim());
                  if (qty == null || qty <= 0) {
                    return;
                  }
                  await ApiService.restockProduct(product['id'], qty);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  _loadProducts();
                },
                child: const Text('Restock'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.card,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.subtext,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Produk Kedai'),
              Tab(text: 'Cari Library'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1 — Produk Kedai
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 56,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tiada produk',
                            style: TextStyle(
                              color: AppColors.subtext,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _tabController.animateTo(1),
                            child: const Text('Cari dari Library →'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final stok = product['stok'] ?? 0;
                          final lowStock = stok <= 5;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: lowStock
                                    ? AppColors.danger.withOpacity(0.3)
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: lowStock
                                        ? AppColors.dangerLight
                                        : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: lowStock
                                        ? AppColors.danger
                                        : AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product['nama'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.text,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (product['library_id'] != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Library',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            'RM ${(product['harga'] as num).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Stok: $stok',
                                            style: TextStyle(
                                              color: lowStock
                                                  ? AppColors.danger
                                                  : AppColors.subtext,
                                              fontSize: 12,
                                              fontWeight: lowStock
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (lowStock)
                                            const Text(
                                              ' ⚠️',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                        ],
                                      ),
                                      if (product['barcode'] != null)
                                        Text(
                                          product['barcode'],
                                          style: const TextStyle(
                                            color: AppColors.subtext,
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showRestock(product),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Restock',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

              // Tab 2 — Cari Library
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.card,
                    child: TextField(
                      controller: _librarySearchController,
                      onChanged: _searchLibrary,
                      decoration: InputDecoration(
                        hintText: 'Cari nama, barcode atau brand...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _librarySearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _librarySearchController.clear();
                                  setState(() => _libraryResults = []);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _librarySearching
                        ? const Center(child: CircularProgressIndicator())
                        : _libraryResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_outlined,
                                  size: 56,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _librarySearchController.text.isEmpty
                                      ? 'Taip untuk cari produk dalam library'
                                      : 'Tiada produk dijumpai',
                                  style: const TextStyle(
                                    color: AppColors.subtext,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _libraryResults.length,
                            itemBuilder: (context, index) {
                              final item = _libraryResults[index];
                              return GestureDetector(
                                onTap: () => _showAddFromLibrary(item),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['nama'] ?? '-',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.text,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                if (item['brand'] != null)
                                                  Text(
                                                    item['brand'],
                                                    style: const TextStyle(
                                                      color: AppColors.subtext,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                if (item['brand'] != null &&
                                                    item['barcode'] != null)
                                                  const Text(
                                                    ' · ',
                                                    style: TextStyle(
                                                      color: AppColors.subtext,
                                                    ),
                                                  ),
                                                if (item['barcode'] != null)
                                                  Text(
                                                    item['barcode'],
                                                    style: const TextStyle(
                                                      color: AppColors.subtext,
                                                      fontSize: 11,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (item['kategori'] != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item['kategori'],
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Tap untuk tambah',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.subtext,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
