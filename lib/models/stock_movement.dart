enum StockMoveType { entry, exit, adjustment }

class StockMovement {
  int id = 0;
  late int productId;
  late StockMoveType type;
  late double quantity;
  late double previousStock;
  late double newStock;
  String? reason;
  String? reference;
  DateTime? createdAt;
  int? userId;

  StockMovement() {
    createdAt = DateTime.now();
  }
}
