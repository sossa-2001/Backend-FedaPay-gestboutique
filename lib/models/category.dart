class Category {
  int id = 0;
  late String name;
  String? description;
  int? color;
  int? icon;
  DateTime? createdAt;
  DateTime? updatedAt;

  Category() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }
}
