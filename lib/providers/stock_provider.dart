import 'package:flutter/material.dart';
import '../models/stock_movement.dart';
import '../data/database_service.dart';
import '../services/sync_service.dart';
import 'product_provider.dart';

class StockProvider extends ChangeNotifier {
  final DatabaseService _db;
  final ProductProvider _productProvider;
  final SyncService _sync;
  List<StockMovement> _movements = [];
  bool _isLoading = false;

  StockProvider(this._db, this._productProvider, this._sync);

  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;

  Future<void> loadMovements() async {
    _isLoading = true;
    notifyListeners();
    _movements = await _db.loadStockMovements();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMovement(StockMovement movement) async {
    await _db.addStockMovement(movement);
    _sync.syncStockMovement(movement);
    await Future.wait([loadMovements(), _productProvider.loadProducts()]);
  }

  Future<List<StockMovement>> getMovementsForProduct(int productId) async {
    return _db.getMovementsForProduct(productId);
  }
}
