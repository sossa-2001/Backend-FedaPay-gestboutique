class Product {
  int id = 0;
  late String name;
  String? description;
  String? barcode;
  late double price;
  double? costPrice;
  int? categoryId;
  late double stockQuantity;
  double? minStock;
  String? imagePath;
  bool isActive = true;
  DateTime? createdAt;
  DateTime? updatedAt;

  Product() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    stockQuantity = 0;
    price = 0;
  }
}
