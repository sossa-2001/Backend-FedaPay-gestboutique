import 'package:sembast/sembast.dart';
import 'database_platform.dart'
    if (dart.library.html) 'database_platform_web.dart';
import 'database_service.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/order.dart';

class SembastDatabase implements DatabaseService {
  Database? _settingsDb;
  Database? _db;
  String? _currentStoreId;

  StoreRef<int, Map<String, dynamic>> get _categories =>
      intMapStoreFactory.store('categories');
  StoreRef<int, Map<String, dynamic>> get _products =>
      intMapStoreFactory.store('products');
  StoreRef<int, Map<String, dynamic>> get _stockMovements =>
      intMapStoreFactory.store('stock_movements');
  StoreRef<int, Map<String, dynamic>> get _orders =>
      intMapStoreFactory.store('orders');
  StoreRef<int, Map<String, dynamic>> get _orderItems =>
      intMapStoreFactory.store('order_items');
  StoreRef<int, Map<String, dynamic>> get _clients =>
      intMapStoreFactory.store('clients');
  StoreRef<int, Map<String, dynamic>> get _settings =>
      intMapStoreFactory.store('settings');
  StoreRef<String, Map<String, dynamic>> get _reports =>
      stringMapStoreFactory.store('reports');

  int _nextCategoryId = 1;
  int _nextProductId = 1;
  int _nextMovementId = 1;
  int _nextOrderId = 1;
  int _nextOrderItemId = 1;
  int _nextClientId = 1;

  @override
  Future<void> init() async {
    if (_db != null && _db != _settingsDb) await _db!.close();
    _currentStoreId = null;
    final path = await databasePath();
    if (_settingsDb == null) {
      _settingsDb = await databaseFactory.openDatabase(path);
    }
    _db = _settingsDb;
    await _initCounters();
  }

  @override
  Future<void> initForStore(String storeId) async {
    if (_currentStoreId == storeId) return;
    _currentStoreId = storeId;
    if (_db != null && _db != _settingsDb) await _db!.close();
    final path = await databasePath(storeId: storeId);
    _db = await databaseFactory.openDatabase(path);
    await _initCounters();
    await _migrateIfNeeded();
  }

  Future<void> _migrateIfNeeded() async {
    if (_db == _settingsDb) return;
    final existing = await _products.find(_db!);
    if (existing.isNotEmpty) return;
    final oldRecords = await _products.find(_settingsDb!);
    if (oldRecords.isEmpty) return;

    final stores = [
      _categories,
      _clients,
      _products,
      _stockMovements,
      _orders,
      _orderItems,
    ];
    for (final store in stores) {
      final records = await store.find(_settingsDb!);
      for (final record in records) {
        await store.record(record.key).put(_db!, record.value);
      }
    }
    // Also migrate reports
    final oldReports = await _reports.find(_settingsDb!);
    for (final record in oldReports) {
      await _reports.record(record.key).put(_db!, record.value);
    }
  }

  Future<void> _initCounters() async {
    _nextCategoryId = (await _getMaxId(_categories)) + 1;
    _nextProductId = (await _getMaxId(_products)) + 1;
    _nextMovementId = (await _getMaxId(_stockMovements)) + 1;
    _nextOrderId = (await _getMaxId(_orders)) + 1;
    _nextOrderItemId = (await _getMaxId(_orderItems)) + 1;
    _nextClientId = (await _getMaxId(_clients)) + 1;
  }

  Future<int> _getMaxId(StoreRef<int, Map<String, dynamic>> store) async {
    final records = await store.find(_db!);
    if (records.isEmpty) return 0;
    return records.map((r) => r.key).reduce((a, b) => a > b ? a : b);
  }

  // === Categories ===

  @override
  Future<List<Category>> loadCategories() async {
    final records = await _categories.find(_db!);
    return records.map((r) => _categoryFromMap(r.value, r.key)).toList();
  }

  @override
  Future<void> addCategory(Category category) async {
    final id = _nextCategoryId++;
    category.id = id;
    await _categories.add(_db!, _categoryToMap(category));
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _categories
        .record(category.id)
        .update(_db!, _categoryToMap(category));
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _categories.record(id).delete(_db!);
  }

  Map<String, dynamic> _categoryToMap(Category c) => {
    if (c.description != null) 'description': c.description,
    'color': c.color,
    'icon': c.icon,
    if (c.createdAt != null) 'createdAt': c.createdAt!.millisecondsSinceEpoch,
  };

  Category _categoryFromMap(Map<String, dynamic> map, int id) => Category()
    ..id = id
    ..name = map['name'] as String? ?? ''
    ..description = map['description'] as String?
    ..color = map['color'] as int?
    ..icon = map['icon'] as int?
    ..createdAt = map['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
        : null;

  // === Clients ===

  @override
  Future<List<Client>> loadClients() async {
    final records = await _clients.find(_db!);
    return records.map((r) => _clientFromMap(r.value, r.key)).toList();
  }

  @override
  Future<void> addClient(Client client) async {
    final id = _nextClientId++;
    client.id = id;
    await _clients.add(_db!, _clientToMap(client));
  }

  @override
  Future<void> updateClient(Client client) async {
    await _clients.record(client.id).update(_db!, _clientToMap(client));
  }

  @override
  Future<void> deleteClient(int id) async {
    await _clients.record(id).delete(_db!);
  }

  Map<String, dynamic> _clientToMap(Client c) => {
    'name': c.name,
    if (c.phone != null) 'phone': c.phone,
    if (c.email != null) 'email': c.email,
    if (c.address != null) 'address': c.address,
    if (c.createdAt != null) 'createdAt': c.createdAt!.millisecondsSinceEpoch,
  };

  Client _clientFromMap(Map<String, dynamic> map, int id) => Client()
    ..id = id
    ..name = map['name'] as String? ?? ''
    ..phone = map['phone'] as String?
    ..email = map['email'] as String?
    ..address = map['address'] as String?
    ..createdAt = map['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
        : null;

  // === Products ===

  @override
  Future<List<Product>> loadProducts() async {
    final records = await _products.find(_db!);
    return records.map((r) => _productFromMap(r.value, r.key)).toList();
  }

  @override
  Future<void> addProduct(Product product) async {
    final id = _nextProductId++;
    product.id = id;
    product.createdAt ??= DateTime.now();
    product.updatedAt ??= DateTime.now();
    await _products.add(_db!, _productToMap(product));
  }

  @override
  Future<void> updateProduct(Product product) async {
    product.updatedAt = DateTime.now();
    await _products.record(product.id).update(_db!, _productToMap(product));
  }

  @override
  Future<void> deleteProduct(int id) async {
    await _products.record(id).delete(_db!);
  }

  @override
  Future<Product?> getProduct(int id) async {
    final record = await _products.record(id).get(_db!);
    if (record == null) return null;
    return _productFromMap(record, id);
  }

  @override
  Future<void> updateProductStock(int productId, double quantity) async {
    final product = await getProduct(productId);
    if (product != null) {
      product.stockQuantity = quantity;
      product.updatedAt = DateTime.now();
      await _products.record(productId).update(_db!, _productToMap(product));
    }
  }

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

  Product _productFromMap(Map<String, dynamic> map, int id) => Product()
    ..id = id
    ..name = map['name'] as String? ?? ''
    ..description = map['description'] as String?
    ..barcode = map['barcode'] as String?
    ..price = (map['price'] as num?)?.toDouble() ?? 0
    ..costPrice = (map['costPrice'] as num?)?.toDouble()
    ..categoryId = map['categoryId'] as int?
    ..stockQuantity = (map['stockQuantity'] as num?)?.toDouble() ?? 0
    ..minStock = (map['minStock'] as num?)?.toDouble()
    ..imagePath = map['imagePath'] as String?
    ..isActive = map['isActive'] as bool? ?? true
    ..createdAt = map['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
        : null
    ..updatedAt = map['updatedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
        : null;

  // === Stock Movements ===

  @override
  Future<List<StockMovement>> loadStockMovements() async {
    final records = await _stockMovements.find(_db!);
    final list = records.map((r) => _movementFromMap(r.value, r.key)).toList();
    list.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return list;
  }

  @override
  Future<void> addStockMovement(StockMovement movement) async {
    final product = await getProduct(movement.productId);
    if (product != null) {
      movement.previousStock = product.stockQuantity;
      switch (movement.type) {
        case StockMoveType.entry:
          product.stockQuantity += movement.quantity;
          break;
        case StockMoveType.exit:
          product.stockQuantity -= movement.quantity;
          break;
        case StockMoveType.adjustment:
          product.stockQuantity = movement.quantity;
          movement.quantity = product.stockQuantity - movement.previousStock;
          break;
      }
      movement.newStock = product.stockQuantity;
      await _products.record(product.id).update(_db!, _productToMap(product));
    }
    final id = _nextMovementId++;
    movement.id = id;
    await _stockMovements.add(_db!, _movementToMap(movement));
  }

  @override
  Future<List<StockMovement>> getMovementsForProduct(int productId) async {
    final records = await _stockMovements.find(_db!);
    final list =
        records
            .where((r) => r.value['productId'] == productId)
            .map((r) => _movementFromMap(r.value, r.key))
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
    return list;
  }

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

  StockMovement _movementFromMap(Map<String, dynamic> map, int id) =>
      StockMovement()
        ..id = id
        ..productId = map['productId'] as int? ?? 0
        ..type = StockMoveType.values[map['type'] as int? ?? 0]
        ..quantity = (map['quantity'] as num?)?.toDouble() ?? 0
        ..previousStock = (map['previousStock'] as num?)?.toDouble() ?? 0
        ..newStock = (map['newStock'] as num?)?.toDouble() ?? 0
        ..reason = map['reason'] as String?
        ..reference = map['reference'] as String?
        ..createdAt = map['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
            : null
        ..userId = map['userId'] as int?;

  // === Orders ===

  @override
  Future<List<Order>> loadOrders() async {
    final records = await _orders.find(_db!);
    final list = records.map((r) => _orderFromMap(r.value, r.key)).toList();
    list.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return list;
  }

  @override
  Future<List<Order>> loadOrdersWithItems() async {
    final orders = await loadOrders();
    final allItems = await _orderItems.find(_db!);
    for (final order in orders) {
      final orderItems = allItems
          .where((r) => r.value['orderId'] == order.id)
          .map((r) => _orderItemFromMap(r.value, r.key));
      order.items.addAll(orderItems);
    }
    return orders;
  }

  @override
  Future<Order?> getOrderWithItems(int orderId) async {
    final record = await _orders.record(orderId).get(_db!);
    if (record == null) return null;
    final order = _orderFromMap(record, orderId);
    final items = await _orderItems.find(_db!);
    order.items.addAll(
      items
          .where((r) => r.value['orderId'] == orderId)
          .map((r) => _orderItemFromMap(r.value, r.key)),
    );
    return order;
  }

  @override
  Future<void> addOrder(Order order) async {
    final id = _nextOrderId++;
    order.id = id;
    order.createdAt ??= DateTime.now();
    final orderMap = _orderToMap(order);
    // Remove items from order map (stored separately)
    final orderKey = await _orders.add(_db!, orderMap);
    // Update the order id to the auto-generated key
    order.id = orderKey;
    for (final item in order.items) {
      final itemId = _nextOrderItemId++;
      item.id = itemId;
      item.orderId = orderKey;
      await _orderItems.add(_db!, _orderItemToMap(item));
    }
  }

  @override
  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    final map = await _orders.record(orderId).get(_db!);
    if (map != null) {
      map['status'] = status.index;
      await _orders.record(orderId).update(_db!, map);
    }
  }

  Map<String, dynamic> _orderToMap(Order o) => {
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

  Order _orderFromMap(Map<String, dynamic> map, int id) => Order()
    ..id = id
    ..orderNumber = map['orderNumber'] as String? ?? ''
    ..status = OrderStatus.values[map['status'] as int? ?? 0]
    ..subtotal = (map['subtotal'] as num?)?.toDouble() ?? 0
    ..tax = (map['tax'] as num?)?.toDouble() ?? 0
    ..discount = (map['discount'] as num?)?.toDouble() ?? 0
    ..total = (map['total'] as num?)?.toDouble() ?? 0
    ..totalProfit = (map['totalProfit'] as num?)?.toDouble() ?? 0
    ..paymentMethod = map['paymentMethod'] as String?
    ..customerName = map['customerName'] as String?
    ..createdAt = map['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
        : null;

  Map<String, dynamic> _orderItemToMap(OrderItem i) => {
    'orderId': i.orderId,
    'productId': i.productId,
    'productName': i.productName,
    'quantity': i.quantity,
    'unitPrice': i.unitPrice,
    'totalPrice': i.totalPrice,
    if (i.costPrice != null) 'costPrice': i.costPrice,
  };

  @override
  Future<String?> getSetting(String key) async {
    final doc = await _settings.record(1).get(_settingsDb!);
    return doc?[key] as String?;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    final doc = (await _settings.record(1).get(_settingsDb!)) ?? {};
    doc[key] = value;
    await _settings.record(1).put(_settingsDb!, doc);
  }

  OrderItem _orderItemFromMap(Map<String, dynamic> map, int id) => OrderItem()
    ..id = id
    ..orderId = map['orderId'] as int? ?? 0
    ..productId = map['productId'] as int? ?? 0
    ..productName = map['productName'] as String? ?? ''
    ..quantity = (map['quantity'] as num?)?.toDouble() ?? 1
    ..unitPrice = (map['unitPrice'] as num?)?.toDouble() ?? 0
    ..totalPrice = (map['totalPrice'] as num?)?.toDouble() ?? 0
    ..costPrice = (map['costPrice'] as num?)?.toDouble();

  // === Import (sync Firestore → local) ===

  @override
  Future<void> importCategory(int id, Map<String, dynamic> data) async {
    await _categories.record(id).put(_db!, data);
    if (id >= _nextCategoryId) _nextCategoryId = id + 1;
  }

  @override
  Future<void> importClient(int id, Map<String, dynamic> data) async {
    await _clients.record(id).put(_db!, data);
    if (id >= _nextClientId) _nextClientId = id + 1;
  }

  @override
  Future<void> importProduct(int id, Map<String, dynamic> data) async {
    await _products.record(id).put(_db!, data);
    if (id >= _nextProductId) _nextProductId = id + 1;
  }

  @override
  Future<void> importStockMovement(int id, Map<String, dynamic> data) async {
    await _stockMovements.record(id).put(_db!, data);
    if (id >= _nextMovementId) _nextMovementId = id + 1;
  }

  @override
  Future<void> importOrder(int id, Map<String, dynamic> data) async {
    await _orders.record(id).put(_db!, data);
    if (id >= _nextOrderId) _nextOrderId = id + 1;
  }

  @override
  Future<void> importOrderItem(
    int id,
    int orderId,
    Map<String, dynamic> data,
  ) async {
    await _orderItems.record(id).put(_db!, data);
    if (id >= _nextOrderItemId) _nextOrderItemId = id + 1;
  }

  @override
  Future<void> saveReport(String key, Map<String, dynamic> data) async {
    await _reports.record(key).put(_db!, data);
  }

  @override
  Future<Map<String, dynamic>?> loadReport(String key) async {
    return await _reports.record(key).get(_db!);
  }

  @override
  Future<List<Map<String, dynamic>>> listReports(String prefix) async {
    final records = await _reports.find(_db!);
    return records
        .where((r) => prefix.isEmpty || r.key.startsWith(prefix))
        .map((r) => {'key': r.key, ...r.value})
        .toList();
  }

  @override
  Future<void> clearAll() async {
    await _categories.delete(_db!);
    await _clients.delete(_db!);
    await _products.delete(_db!);
    await _stockMovements.delete(_db!);
    await _orders.delete(_db!);
    await _orderItems.delete(_db!);
    await _reports.delete(_db!);
    _nextCategoryId = 1;
    _nextProductId = 1;
    _nextMovementId = 1;
    _nextOrderId = 1;
    _nextOrderItemId = 1;
    _nextClientId = 1;
  }
}
