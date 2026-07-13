import '../models/category.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/order.dart';

abstract class DatabaseService {
  Future<void> init();
  Future<void> initForStore(String storeId);

  // Categories
  Future<List<Category>> loadCategories();
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int id);

  // Clients
  Future<List<Client>> loadClients();
  Future<void> addClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> deleteClient(int id);

  // Products
  Future<List<Product>> loadProducts();
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<Product?> getProduct(int id);
  Future<void> updateProductStock(int productId, double quantity);

  // Stock movements
  Future<List<StockMovement>> loadStockMovements();
  Future<void> addStockMovement(StockMovement movement);
  Future<List<StockMovement>> getMovementsForProduct(int productId);

  // Orders
  Future<List<Order>> loadOrders();
  Future<List<Order>> loadOrdersWithItems();
  Future<Order?> getOrderWithItems(int orderId);
  Future<void> addOrder(Order order);
  Future<void> updateOrderStatus(int orderId, OrderStatus status);
  Future<void> updateOrderPayment(int orderId, PaymentStatus paymentStatus, double amountPaid);

  // Settings
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);

  // Reports
  Future<void> saveReport(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> loadReport(String key);
  Future<List<Map<String, dynamic>>> listReports(String prefix);

  // Import (pour sync Firestore → local)
  Future<void> importCategory(int id, Map<String, dynamic> data);
  Future<void> importClient(int id, Map<String, dynamic> data);
  Future<void> importProduct(int id, Map<String, dynamic> data);
  Future<void> importStockMovement(int id, Map<String, dynamic> data);
  Future<void> importOrder(int id, Map<String, dynamic> data);
  Future<void> importOrderItem(int id, int orderId, Map<String, dynamic> data);
  Future<void> importSettings(Map<String, dynamic> data);
  Future<void> importReport(String key, Map<String, dynamic> data);
  Future<void> clearAll();
}
