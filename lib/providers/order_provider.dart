import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/stock_movement.dart';
import '../data/database_service.dart';
import '../services/sync_service.dart';
import 'client_provider.dart';
import 'stock_provider.dart';

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

  Future<void> cancelOrder(
    Order order, {
    StockProvider? stockProvider,
    ClientProvider? clientProvider,
  }) async {
    await _db.updateOrderStatus(order.id, OrderStatus.cancelled);
    _sync.updateOrderStatus(order.id, OrderStatus.cancelled.index);

    if (stockProvider != null) {
      for (final item in order.items) {
        final reversal = StockMovement()
          ..productId = item.productId
          ..type = StockMoveType.entry
          ..quantity = item.quantity
          ..reason = 'Annulation - ${order.orderNumber}';
        await stockProvider.addMovement(reversal);
      }
    }

    if (clientProvider != null && order.customerId != null) {
      final client = clientProvider.clients
          .where((c) => c.id == order.customerId)
          .firstOrNull;
      if (client != null) {
        client.balance -= (order.total - order.amountPaid);
        await clientProvider.updateClient(client);
      }
    }

    await loadOrdersWithItems();
  }

  Future<void> updatePayment(
    Order order,
    PaymentStatus newStatus,
    double newAmountPaid, {
    ClientProvider? clientProvider,
  }) async {
    final oldDue = order.total - order.amountPaid;
    final newDue = order.total - newAmountPaid;
    final balanceDelta = newDue - oldDue;

    await _db.updateOrderPayment(order.id, newStatus, newAmountPaid);
    order
      ..paymentStatus = newStatus
      ..amountPaid = newAmountPaid
      ..updatedAt = DateTime.now();
    _sync.syncOrder(order);

    if (clientProvider != null && order.customerId != null) {
      final client = clientProvider.clients
          .where((c) => c.id == order.customerId)
          .firstOrNull;
      if (client != null) {
        client.balance += balanceDelta;
        await clientProvider.updateClient(client);
      }
    }

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
