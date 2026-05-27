class Product {
  final String id;
  final String nama;
  final double harga;
  final String? barcode;
  final int stok;
  final String tenantId;

  Product({
    required this.id,
    required this.nama,
    required this.harga,
    this.barcode,
    required this.stok,
    required this.tenantId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nama: json['nama'],
      harga: (json['harga'] as num).toDouble(),
      barcode: json['barcode'],
      stok: json['stok'],
      tenantId: json['tenant_id'],
    );
  }
}
