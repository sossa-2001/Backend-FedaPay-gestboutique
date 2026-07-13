enum OrderStatus { pending, completed, cancelled }
enum PaymentStatus { paid, partial, unpaid, deposit }

class Order {
  int id = 0;
  late String orderNumber;
  late OrderStatus status;
  late double subtotal;
  double tax = 0;
  double discount = 0;
  late double total;
  double totalProfit = 0;
  String? paymentMethod;
  String? customerName;
  int? customerId;
  String? sellerName;
  PaymentStatus paymentStatus = PaymentStatus.paid;
  double amountPaid = 0;
  DateTime? createdAt;
  DateTime? updatedAt;

  double get amountDue => total - amountPaid;

  bool get isFullyPaid => amountPaid >= total;
  bool get isPartial => amountPaid > 0 && amountPaid < total;
  bool get isUnpaid => amountPaid <= 0;

  final items = <OrderItem>[];

  Order() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    status = OrderStatus.pending;
    subtotal = 0;
    total = 0;
  }
}

class OrderItem {
  int id = 0;
  late int orderId;
  late int productId;
  late String productName;
  late double quantity;
  late double unitPrice;
  late double totalPrice;
  double? costPrice;

  OrderItem() {
    quantity = 1;
    unitPrice = 0;
    totalPrice = 0;
  }
}
