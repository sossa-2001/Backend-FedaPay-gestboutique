import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/stock_movement.dart';
import '../providers/order_provider.dart';
import '../providers/stock_provider.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  double get profit {
    final cost = product.costPrice;
    if (cost == null) return 0;
    return (product.price - cost) * quantity;
  }
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

  Future<void> checkout({String? customerName}) async {
    if (_cart.isEmpty) return;

    final order = Order()
      ..orderNumber = 'CMD-${DateTime.now().millisecondsSinceEpoch}'
      ..status = OrderStatus.completed
      ..subtotal = subtotal
      ..total = subtotal
      ..customerName = customerName;

    for (final cartItem in _cart) {
      final orderItem = OrderItem()
        ..productId = cartItem.product.id
        ..productName = cartItem.product.name
        ..quantity = cartItem.quantity.toDouble()
        ..unitPrice = cartItem.product.price
        ..totalPrice = cartItem.totalPrice
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
    clearCart();
  }
}
