class Category {
  int id = 0;
  late String name;
  String? description;
  int? color;
  int? icon;
  DateTime? createdAt;

  Category() {
    createdAt = DateTime.now();
  }
}
