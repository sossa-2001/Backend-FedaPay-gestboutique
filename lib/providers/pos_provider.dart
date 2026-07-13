import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/stock_movement.dart';
import '../providers/order_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/client_provider.dart';

class CartItem {
  final Product product;
  int quantity;
  double manualDiscount = 0;

  CartItem({required this.product, this.quantity = 1});

  double get autoDiscountPerUnit {
    if (product.discountTiers.isEmpty) return 0;
    double discount = 0;
    for (final tier in product.discountTiers) {
      if (quantity >= tier.minQuantity) {
        discount = tier.discountAmount;
      }
    }
    return discount;
  }

  double get autoDiscountTotal => autoDiscountPerUnit * quantity;

  double get effectiveUnitPrice => product.price - autoDiscountPerUnit;

  double get totalPrice {
    final auto = autoDiscountPerUnit * quantity;
    final totalManual = manualDiscount;
    return (product.price * quantity) - auto - totalManual;
  }

  double get profit {
    final cost = product.costPrice;
    if (cost == null) return 0;
    return (effectiveUnitPrice - cost) * quantity - manualDiscount;
  }

  double get unitPriceWithAutoDiscount => product.price - autoDiscountPerUnit;
}

class PosProvider extends ChangeNotifier {
  final OrderProvider _orderProvider;
  final StockProvider _stockProvider;

  final List<CartItem> _cart = [];

  PosProvider(this._orderProvider, this._stockProvider);

  List<CartItem> get cart => _cart;
  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalProfit => _cart.fold(0, (sum, item) => sum + item.profit);

  double get totalAutoDiscount =>
      _cart.fold(0.0, (sum, item) => sum + item.autoDiscountTotal);

  double get totalManualDiscount =>
      _cart.fold(0.0, (sum, item) => sum + item.manualDiscount);

  double get totalDiscount => totalAutoDiscount + totalManualDiscount;

  void addToCart(Product product) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_cart[index].quantity < product.stockQuantity) {
        _cart[index].quantity++;
      }
    } else {
      if (product.stockQuantity > 0) {
        _cart.add(CartItem(product: product));
      }
    }
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index].quantity = quantity;
      // Clamp manual discount to product max
      final maxDisc = _cart[index].product.manualDiscountMax;
      if (maxDisc != null && _cart[index].manualDiscount > maxDisc) {
        _cart[index].manualDiscount = maxDisc;
      }
    }
    notifyListeners();
  }

  void setManualDiscount(int index, double value) {
    if (index < 0 || index >= _cart.length) return;
    final item = _cart[index];
    final maxDisc = item.product.manualDiscountMax;
    if (maxDisc != null) {
      item.manualDiscount = value.clamp(0, maxDisc);
    } else {
      item.manualDiscount = value.clamp(0, double.infinity);
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cart.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<void> checkout({
    String? customerName,
    int? customerId,
    String? sellerName,
    PaymentStatus paymentStatus = PaymentStatus.paid,
    double amountPaid = 0,
    ClientProvider? clientProvider,
  }) async {
    if (_cart.isEmpty) return;

    final order = Order()
      ..orderNumber = 'CMD-${DateTime.now().millisecondsSinceEpoch}'
      ..status = OrderStatus.completed
      ..subtotal = subtotal + totalDiscount
      ..discount = totalDiscount
      ..total = subtotal
      ..customerName = customerName
      ..customerId = customerId
      ..sellerName = sellerName
      ..paymentStatus = paymentStatus
      ..amountPaid = amountPaid.clamp(0, subtotal);

    for (final cartItem in _cart) {
      final unitPrice = cartItem.unitPriceWithAutoDiscount;
      final appliedManual = cartItem.manualDiscount;
      final itemTotal = (unitPrice * cartItem.quantity) - appliedManual;

      final orderItem = OrderItem()
        ..productId = cartItem.product.id
        ..productName = cartItem.product.name
        ..quantity = cartItem.quantity.toDouble()
        ..unitPrice = unitPrice
        ..totalPrice = itemTotal
        ..costPrice = cartItem.product.costPrice;
      order.items.add(orderItem);

      final movement = StockMovement()
        ..productId = cartItem.product.id
        ..type = StockMoveType.exit
        ..quantity = cartItem.quantity.toDouble()
        ..reason = 'Vente - ${order.orderNumber}';
      await _stockProvider.addMovement(movement);
    }

    order.totalProfit = _cart.fold(0.0, (sum, item) => sum + item.profit);

    await _orderProvider.addOrder(order);

    if (clientProvider != null && customerId != null) {
      final clients = clientProvider.clients;
      final client = clients.where((c) => c.id == customerId).firstOrNull;
      if (client != null) {
        client.balance += order.total - amountPaid;
        await clientProvider.updateClient(client);
      }
    }

    clearCart();
  }
}
