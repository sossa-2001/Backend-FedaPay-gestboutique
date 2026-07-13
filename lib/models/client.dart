class Client {
  int id = 0;
  late String name;
  String? phone;
  String? email;
  String? address;
  double balance = 0;
  DateTime? createdAt;
  DateTime? updatedAt;

  Client() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  bool get hasDebt => balance > 0;
  bool get hasCredit => balance < 0;
}
