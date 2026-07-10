import 'package:flutter/material.dart';
import '../models/order.dart';
import '../data/database_service.dart';
import '../services/sync_service.dart';

class OrderProvider extends ChangeNotifier {
  final DatabaseService _db;
  final SyncService _sync;
  List<Order> _orders = [];
  bool _isLoading = false;

  OrderProvider(this._db, this._sync);

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    _orders = await _db.loadOrders();
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Order>> loadOrdersWithItems() async {
    _orders = await _db.loadOrdersWithItems();
    notifyListeners();
    return _orders;
  }

  Future<Order?> getOrderWithItems(int orderId) async {
    return _db.getOrderWithItems(orderId);
  }

  Future<void> addOrder(Order order) async {
    await _db.addOrder(order);
    _sync.syncOrder(order);
    await loadOrdersWithItems();
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    await _db.updateOrderStatus(orderId, status);
    _sync.updateOrderStatus(orderId, status.index);
    await loadOrdersWithItems();
  }

  double get totalRevenue {
    return _orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0, (sum, o) => sum + o.total);
  }

  int get pendingCount {
    return _orders.where((o) => o.status == OrderStatus.pending).length;
  }

  int get todayOrderCount {
    final today = DateTime.now();
    return _orders
        .where(
          (o) =>
              o.createdAt != null &&
              o.createdAt!.year == today.year &&
              o.createdAt!.month == today.month &&
              o.createdAt!.day == today.day,
        )
        .length;
  }
}
