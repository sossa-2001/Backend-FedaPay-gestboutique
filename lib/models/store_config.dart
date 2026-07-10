class Secretary {
  String id = '';
  late String name;
  late String login;
  late String password;
  String email = '';
  String role = 'secrétaire';
  bool canViewDashboard = true;
  bool canManageProducts = false;
  bool canManageClients = true;
  bool canManageOrders = true;
  bool canManagePos = true;
  bool canManageStock = false;
  bool canViewReports = false;
  bool canManageSettings = false;
  bool canManageSecretaries = false;

  Secretary();

  void applyRole(String newRole) {
    role = newRole;
    if (newRole == 'surveillant') {
      canViewDashboard = true;
      canManageProducts = false;
      canManageClients = false;
      canManageOrders = true;
      canManagePos = true;
      canManageStock = true;
      canViewReports = true;
      canManageSettings = false;
      canManageSecretaries = false;
    } else {
      canViewDashboard = true;
      canManageProducts = false;
      canManageClients = true;
      canManageOrders = true;
      canManagePos = true;
      canManageStock = false;
      canViewReports = false;
      canManageSettings = false;
      canManageSecretaries = false;
    }
  }
}

class StoreConfig {
  String storeId = '';
  late String storeName;
  late String adminLogin;
  late String adminPassword;
  String email = '';
  bool backupEnabled = false;
  bool configured = false;
}
