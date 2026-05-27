import 'package:flutter/material.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.harga * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get grandTotal => _items.fold(0, (sum, item) => sum + item.total);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  // Add product ke cart
  void addProduct(Product product) {
    final existing = _items.where((item) => item.product.id == product.id);

    if (existing.isNotEmpty) {
      // Dah ada dalam cart — tambah quantity
      existing.first.quantity++;
    } else {
      // Baru — add to cart
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  // Remove item dari cart
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // Clear cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Update quantity
  void updateQuantity(String productId, int quantity) {
    final item = _items.firstWhere((item) => item.product.id == productId);
    if (quantity <= 0) {
      removeItem(productId);
    } else {
      item.quantity = quantity;
      notifyListeners();
    }
  }
}
