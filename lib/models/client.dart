class Client {
  int id = 0;
  late String name;
  String? phone;
  String? email;
  String? address;
  DateTime? createdAt;

  Client() {
    createdAt = DateTime.now();
  }
}
