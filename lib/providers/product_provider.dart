import 'package:flutter/material.dart';
import '../models/product.dart';
import '../data/database_service.dart';
import '../services/sync_service.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseService _db;
  final SyncService _sync;
  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';

  ProductProvider(this._db, this._sync);

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final query = _searchQuery.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              (p.barcode?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await _db.loadProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await _db.addProduct(product);
    _sync.syncProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    _sync.syncProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    _sync.deleteProduct(id);
    await loadProducts();
  }

  Future<void> refreshFromCloud() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _sync.pullFromFirestore();
    } catch (_) {}
    await loadProducts();
  }

  Future<void> updateStock(int productId, double quantity) async {
    await _db.updateProductStock(productId, quantity);
    final product = await _db.getProduct(productId);
    if (product != null) _sync.syncProduct(product);
    await loadProducts();
  }

  int get lowStockCount {
    return _products
        .where((p) => p.minStock != null && p.stockQuantity <= p.minStock!)
        .length;
  }

  int get outOfStockCount {
    return _products.where((p) => p.stockQuantity <= 0).length;
  }

  double get totalStockValue {
    return _products.fold(
      0,
      (sum, p) => sum + (p.stockQuantity * (p.costPrice ?? p.price)),
    );
  }
}
