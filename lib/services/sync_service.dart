import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/database_service.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/order.dart' as models;

class SyncService {
  final DatabaseService _db;
  FirebaseFirestore? _firestore;
  bool _initialized = false;
  String _storeId = '';

  Future<void> Function()? onPullComplete;

  SyncService(this._db);

  Future<void> init() async {
    try {
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  void setStoreId(String storeId) {
    _storeId = storeId;
  }

  String _storePath(String collection) {
    if (_storeId.isEmpty) return collection;
    return 'stores/$_storeId/$collection';
  }

  bool get isAvailable => _initialized && _firestore != null;

  Future<void> pullFromFirestore() async {
    if (!isAvailable || _storeId.isEmpty) return;
    try {
      await Future.wait([
        _pullCategories(),
        _pullClients(),
        _pullProducts(),
        _pullStockMovements(),
        _pullOrders(),
      ]).timeout(const Duration(seconds: 60));
      if (onPullComplete != null) await onPullComplete!();
    } catch (_) {}
  }

  Future<void> _pullCategories() async {
    final docs = await _firestore!
        .collection(_storePath('categories'))
        .get()
        .timeout(const Duration(seconds: 20));
    for (final doc in docs.docs) {
      final id = int.tryParse(doc.id);
      if (id == null) continue;
      await _db.importCategory(id, doc.data());
    }
  }

  Future<void> _pullClients() async {
    final docs = await _firestore!
        .collection(_storePath('clients'))
        .get()
        .timeout(const Duration(seconds: 20));
    for (final doc in docs.docs) {
      final id = int.tryParse(doc.id);
      if (id == null) continue;
      await _db.importClient(id, doc.data());
    }
  }

  Future<void> _pullProducts() async {
    final docs = await _firestore!
        .collection(_storePath('products'))
        .get()
        .timeout(const Duration(seconds: 20));
    for (final doc in docs.docs) {
      final id = int.tryParse(doc.id);
      if (id == null) continue;
      await _db.importProduct(id, doc.data());
    }
  }

  Future<void> _pullStockMovements() async {
    final docs = await _firestore!
        .collection(_storePath('stock_movements'))
        .get()
        .timeout(const Duration(seconds: 20));
    for (final doc in docs.docs) {
      final id = int.tryParse(doc.id);
      if (id == null) continue;
      await _db.importStockMovement(id, doc.data());
    }
  }

  Future<void> _pullOrders() async {
    final docs = await _firestore!
        .collection(_storePath('orders'))
        .get()
        .timeout(const Duration(seconds: 20));
    for (final doc in docs.docs) {
      final id = int.tryParse(doc.id);
      if (id == null) continue;
      await _db.importOrder(id, doc.data());
      final items = await doc.reference
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 15));
      for (final item in items.docs) {
        final itemId = int.tryParse(item.id);
        if (itemId == null) continue;
        await _db.importOrderItem(itemId, id, item.data());
      }
    }
  }

  Future<void> syncAll() async {
    if (!isAvailable) return;
    await Future.wait([
      _syncCategories(),
      _syncClients(),
      _syncProducts(),
      _syncStockMovements(),
      _syncOrders(),
      _syncSettings(),
      _syncReports(),
    ]).timeout(const Duration(seconds: 60));
  }

  Future<void> syncCategory(Category category) async {
    if (!isAvailable) return;
    try {
      await _firestore!
          .collection(_storePath('categories'))
          .doc(category.id.toString())
          .set(_categoryToMap(category))
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> deleteCategory(int id) async {
    if (!isAvailable) return;
    try {
      await _firestore!
          .collection(_storePath('categories'))
          .doc(id.toString())
          .delete()
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> syncClient(Client client) async {
    if (!isAvailable) return;
    try {
      await _firestore!
          .collection(_storePath('clients'))
          .doc(client.id.toString())
          .set(_clientToMap(client))
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> deleteClient(int id) async {
    if (!isAvailable) return;
    try {
      await _firestore!
          .collection(_storePath('clients'))
          .doc(id.toString())
          .delete()
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> syncProduct(Product product) async {
    if (!isAvailable) return;
    try {
      await _firestore!
          .collection(_storePath('products'))
          .doc(product.id.toString())
          .set(_productToMap(product))
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> deleteProduct(int id) async {
    if (!isAvailable) return;
    try {
      await _firestore!
          .collection(_storePath('products'))
          .doc(id.toString())
          .delete()
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> syncStockMovement(StockMovement movement) async {
    if (!isAvailable) return;
    try {
      await _firestore!
          .collection(_storePath('stock_movements'))
          .doc(movement.id.toString())
          .set(_movementToMap(movement))
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> syncOrder(models.Order order) async {
    if (!isAvailable) return;
    try {
      final batch = _firestore!.batch();
      final orderRef = _firestore!
          .collection(_storePath('orders'))
          .doc(order.id.toString());
      batch.set(orderRef, _orderToMap(order));
      for (final item in order.items) {
        final itemRef = orderRef.collection('items').doc(item.id.toString());
        batch.set(itemRef, _orderItemToMap(item));
      }
      await batch.commit().timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> updateOrderStatus(int orderId, int statusIndex) async {
    if (!isAvailable) return;
    try {
      await _firestore!
          .collection(_storePath('orders'))
          .doc(orderId.toString())
          .update({'status': statusIndex})
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> syncSettings(Map<String, String> settings) async {
    if (!isAvailable) return;
    try {
      await _firestore!
          .collection(_storePath('settings'))
          .doc('default')
          .set(settings)
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> _syncCategories() async {
    final categories = await _db.loadCategories();
    final batch = _firestore!.batch();
    for (final c in categories) {
      batch.set(
        _firestore!.collection(_storePath('categories')).doc(c.id.toString()),
        _categoryToMap(c),
      );
    }
    await batch.commit().timeout(const Duration(seconds: 30));
  }

  Future<void> _syncClients() async {
    final clients = await _db.loadClients();
    final batch = _firestore!.batch();
    for (final c in clients) {
      batch.set(
        _firestore!.collection(_storePath('clients')).doc(c.id.toString()),
        _clientToMap(c),
      );
    }
    await batch.commit().timeout(const Duration(seconds: 30));
  }

  Future<void> _syncProducts() async {
    final products = await _db.loadProducts();
    final batch = _firestore!.batch();
    for (final p in products) {
      batch.set(
        _firestore!.collection(_storePath('products')).doc(p.id.toString()),
        _productToMap(p),
      );
    }
    await batch.commit().timeout(const Duration(seconds: 30));
  }

  Future<void> _syncStockMovements() async {
    final movements = await _db.loadStockMovements();
    final batch = _firestore!.batch();
    for (final m in movements) {
      batch.set(
        _firestore!
            .collection(_storePath('stock_movements'))
            .doc(m.id.toString()),
        _movementToMap(m),
      );
    }
    await batch.commit().timeout(const Duration(seconds: 30));
  }

  Future<void> _syncOrders() async {
    final orders = await _db.loadOrdersWithItems();
    for (final order in orders) {
      final batch = _firestore!.batch();
      final orderRef = _firestore!
          .collection(_storePath('orders'))
          .doc(order.id.toString());
      batch.set(orderRef, _orderToMap(order));
      for (final item in order.items) {
        final itemRef = orderRef.collection('items').doc(item.id.toString());
        batch.set(itemRef, _orderItemToMap(item));
      }
      await batch.commit().timeout(const Duration(seconds: 15));
    }
  }

  Future<void> _syncSettings() async {
    final companyName = await _db.getSetting('companyName');
    final isDarkMode = await _db.getSetting('isDarkMode');
    final map = <String, String>{};
    if (companyName != null) map['companyName'] = companyName;
    if (isDarkMode != null) map['isDarkMode'] = isDarkMode;
    if (map.isNotEmpty) {
      await _firestore!
          .collection(_storePath('settings'))
          .doc('default')
          .set(map)
          .timeout(const Duration(seconds: 15));
    }
  }

  void syncReport(String key, Map<String, dynamic> data) {
    if (!isAvailable) return;
    _firestore!
        .collection(_storePath('reports'))
        .doc(key)
        .set(data)
        .timeout(const Duration(seconds: 15))
        .catchError((_) {});
  }

  Future<void> _syncReports() async {
    final records = await _db.listReports('');
    for (final r in records) {
      _firestore!
          .collection(_storePath('reports'))
          .doc(r['key'] as String? ?? '')
          .set(r)
          .timeout(const Duration(seconds: 15))
          .catchError((_) {});
    }
  }

  Map<String, dynamic> _categoryToMap(Category c) => {
    'name': c.name,
    if (c.description != null) 'description': c.description,
    'color': c.color,
    'icon': c.icon,
    if (c.createdAt != null) 'createdAt': c.createdAt!.millisecondsSinceEpoch,
  };

  Map<String, dynamic> _clientToMap(Client c) => {
    'name': c.name,
    if (c.phone != null) 'phone': c.phone,
    if (c.email != null) 'email': c.email,
    if (c.address != null) 'address': c.address,
    if (c.createdAt != null) 'createdAt': c.createdAt!.millisecondsSinceEpoch,
  };

  Map<String, dynamic> _productToMap(Product p) => {
    'name': p.name,
    if (p.description != null) 'description': p.description,
    if (p.barcode != null) 'barcode': p.barcode,
    'price': p.price,
    if (p.costPrice != null) 'costPrice': p.costPrice,
    if (p.categoryId != null) 'categoryId': p.categoryId,
    'stockQuantity': p.stockQuantity,
    if (p.minStock != null) 'minStock': p.minStock,
    if (p.imagePath != null) 'imagePath': p.imagePath,
    'isActive': p.isActive,
    if (p.createdAt != null) 'createdAt': p.createdAt!.millisecondsSinceEpoch,
    if (p.updatedAt != null) 'updatedAt': p.updatedAt!.millisecondsSinceEpoch,
  };

  Map<String, dynamic> _movementToMap(StockMovement m) => {
    'productId': m.productId,
    'type': m.type.index,
    'quantity': m.quantity,
    'previousStock': m.previousStock,
    'newStock': m.newStock,
    if (m.reason != null) 'reason': m.reason,
    if (m.reference != null) 'reference': m.reference,
    if (m.createdAt != null) 'createdAt': m.createdAt!.millisecondsSinceEpoch,
    if (m.userId != null) 'userId': m.userId,
  };

  Map<String, dynamic> _orderToMap(models.Order o) => {
    'orderNumber': o.orderNumber,
    'status': o.status.index,
    'subtotal': o.subtotal,
    'tax': o.tax,
    'discount': o.discount,
    'total': o.total,
    'totalProfit': o.totalProfit,
    if (o.paymentMethod != null) 'paymentMethod': o.paymentMethod,
    if (o.customerName != null) 'customerName': o.customerName,
    if (o.createdAt != null) 'createdAt': o.createdAt!.millisecondsSinceEpoch,
  };

  Map<String, dynamic> _orderItemToMap(models.OrderItem i) => {
    'orderId': i.orderId,
    'productId': i.productId,
    'productName': i.productName,
    'quantity': i.quantity,
    'unitPrice': i.unitPrice,
    'totalPrice': i.totalPrice,
    if (i.costPrice != null) 'costPrice': i.costPrice,
  };
}
