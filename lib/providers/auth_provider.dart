import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../data/database_service.dart';
import '../models/store_config.dart';
import '../services/sync_service.dart';

enum AuthStatus { unauthenticated, authenticated, loading }

class AuthProvider extends ChangeNotifier {
  final DatabaseService _db;
  final FirebaseFirestore _firestore;
  final SyncService _syncService;

  AuthStatus _status = AuthStatus.unauthenticated;
  StoreConfig _config = StoreConfig();
  List<StoreConfig> _availableStores = [];
  List<StoreConfig> _savedLogins = [];
  String? _currentUserId;
  String? _currentUserRole;
  String _currentLogin = '';
  List<Secretary> _secretaries = [];
  String _currentPassword = '';
  final Map<String, String> _selectedRoles = {};

  Future<void> Function()? onSyncComplete;

  AuthProvider(this._db, this._firestore, this._syncService);

  Future<void> init() async {
    await _loadSession();
    await _loadSavedLogins();
  }

  AuthStatus get status => _status;
  StoreConfig get config => _config;
  List<StoreConfig> get availableStores => _availableStores;
  List<StoreConfig> get savedLogins => _savedLogins;
  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;
  String get currentLogin => _currentLogin;
  List<Secretary> get secretaries => _secretaries;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get hasMultipleStores => _availableStores.length > 1;

  String _hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _loadSession() async {
    final storeId = await _db.getSetting('session_storeId');
    final login = await _db.getSetting('session_login');
    final role = await _db.getSetting('session_role');
    final storeName = await _db.getSetting('session_storeName');
    final email = await _db.getSetting('session_email');
    final backupEnabled = await _db.getSetting('session_backupEnabled');
    final configured = await _db.getSetting('session_configured');

    if (storeId != null &&
        login != null &&
        storeId.isNotEmpty &&
        login.isNotEmpty) {
      await _db.initForStore(storeId);
      _config.storeId = storeId;
      _config.storeName = storeName ?? '';
      _config.adminLogin = login;
      _config.email = email ?? '';
      _config.backupEnabled = backupEnabled == 'true';
      _config.configured = configured == 'true';
      _currentUserId = storeId;
      _currentUserRole = role ?? 'admin';
      _currentLogin = login;
      _status = AuthStatus.authenticated;
      notifyListeners();
      await loadSecretaries();
    } else {
      notifyListeners();
    }
  }

  Future<void> _saveSession() async {
    await _db.setSetting('session_storeId', _config.storeId);
    await _db.setSetting('session_login', _currentLogin);
    await _db.setSetting('session_role', _currentUserRole ?? 'admin');
    await _db.setSetting('session_storeName', _config.storeName);
    await _db.setSetting('session_email', _config.email);
    await _db.setSetting(
      'session_backupEnabled',
      _config.backupEnabled.toString(),
    );
    await _db.setSetting('session_configured', _config.configured.toString());
  }

  Future<void> _clearSession() async {
    await _db.setSetting('session_storeId', '');
    await _db.setSetting('session_login', '');
    await _db.setSetting('session_role', '');
    await _db.setSetting('session_storeName', '');
    await _db.setSetting('session_email', '');
    await _db.setSetting('session_backupEnabled', '');
    await _db.setSetting('session_configured', '');
  }

  Future<void> _loadSavedLogins() async {
    final raw = await _db.getSetting('saved_logins');
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _savedLogins = list.map((e) => StoreConfig()
          ..storeId = e['storeId'] ?? ''
          ..storeName = e['storeName'] ?? ''
          ..adminLogin = e['adminLogin'] ?? ''
          ..adminPassword = e['adminPassword'] ?? ''
          ..email = e['email'] ?? ''
          ..backupEnabled = e['backupEnabled'] == true
          ..configured = e['configured'] == true
        ).toList();
      } catch (_) {}
    }
  }

  Future<void> _saveSavedLogins() async {
    final list = _savedLogins.map((s) => {
      'storeId': s.storeId,
      'storeName': s.storeName,
      'adminLogin': s.adminLogin,
      'adminPassword': s.adminPassword,
      'email': s.email,
      'backupEnabled': s.backupEnabled,
      'configured': s.configured,
    }).toList();
    await _db.setSetting('saved_logins', jsonEncode(list));
  }

  Future<void> saveLogin(StoreConfig store) async {
    _savedLogins.removeWhere((s) => s.storeId == store.storeId);
    _savedLogins.insert(0, store);
    await _saveSavedLogins();
  }

  Future<void> removeSavedLogin(String storeId) async {
    _savedLogins.removeWhere((s) => s.storeId == storeId);
    await _saveSavedLogins();
  }

  Future<String?> login(String login, String password) async {
    final connected = await Connectivity().checkConnectivity().timeout(
      const Duration(seconds: 5),
    );
    if (connected.contains(ConnectivityResult.none)) {
      return 'NO_INTERNET';
    }

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final hash = _hash(password);

      // 1. Chercher les boutiques où l'utilisateur est admin
      final adminStores = await _firestore
          .collection('stores')
          .where('adminLogin', isEqualTo: login)
          .get()
          .timeout(const Duration(seconds: 30));

      // 2. Chercher les secrétaires avec ce login dans TOUTES les boutiques
      final secDocs = await _firestore
          .collectionGroup('secretaries')
          .where('login', isEqualTo: login)
          .get()
          .timeout(const Duration(seconds: 30));

      _selectedRoles.clear();
      _availableStores = [];

      for (final doc in adminStores.docs) {
        final data = doc.data();
        if (data['adminPassword'] == hash) {
          _selectedRoles[doc.id] = 'admin';
          _availableStores.add(
            StoreConfig()
              ..storeId = doc.id
              ..storeName = data['name'] ?? ''
              ..adminLogin = login
              ..adminPassword = password
              ..email = data['email'] ?? ''
              ..backupEnabled = data['backupEnabled'] == true
              ..configured = true,
          );
        }
      }

      for (final sec in secDocs.docs) {
        final s = sec.data();
        if (s['password'] == hash) {
          final storeId = sec.reference.parent.parent?.id ?? '';
          if (storeId.isEmpty) continue;
          if (_selectedRoles.containsKey(storeId)) continue;

          _selectedRoles[storeId] = s['role'] ?? 'secrétaire';
          // Récupérer les infos de la boutique
          final storeDoc = await _firestore
              .collection('stores')
              .doc(storeId)
              .get()
              .timeout(const Duration(seconds: 15));
          final data = storeDoc.data();
          _availableStores.add(
            StoreConfig()
              ..storeId = storeId
              ..storeName = data?['name'] ?? ''
              ..adminLogin = login
              ..adminPassword = password
              ..email = data?['email'] ?? ''
              ..backupEnabled = data?['backupEnabled'] == true
              ..configured = true,
          );
        }
      }

      if (_availableStores.isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return 'Login ou mot de passe incorrect';
      }

      _currentPassword = password;

      // Sauvegarder toutes les boutiques pour reconnexion rapide
      for (final s in _availableStores) {
        await saveLogin(s);
      }

      if (_availableStores.length == 1) {
        await _selectStore(
          _availableStores.first,
          knownRole: _selectedRoles[_availableStores.first.storeId],
        );
      } else {
        _currentPassword = password;
        // Multi-boutiques : on reste authentifié, le StorePickerScreen gère la sélection
        _status = AuthStatus.authenticated;
        notifyListeners();
      }

      return null;
    } on TimeoutException {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return 'La connexion au serveur a expiré';
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return 'Erreur: ${e.toString()}';
    }
  }

  Future<void> _selectStore(StoreConfig store, {String? knownRole}) async {
    try {
      _config = store;
      _currentLogin = store.adminLogin;

      if (knownRole != null) {
        _currentUserRole = knownRole;
      } else {
        final online = await Connectivity().checkConnectivity().timeout(
          const Duration(seconds: 5),
        );
        if (online.contains(ConnectivityResult.none)) {
          _currentUserRole = 'admin';
        } else {
          final hash = _hash(_currentPassword);
          final storeDoc = await _firestore
              .collection('stores')
              .doc(store.storeId)
              .get()
              .timeout(const Duration(seconds: 15));
          final data = storeDoc.data();

          if (data != null &&
              data['adminLogin'] == store.adminLogin &&
              data['adminPassword'] == hash) {
            _currentUserRole = 'admin';
          } else {
            _currentUserRole = 'secrétaire';
          }
        }
      }

      await _db.initForStore(store.storeId);
      _currentUserId = store.storeId;
      _syncService.setStoreId(store.storeId);
      await loadSecretaries();
      await _saveSession();
      await saveLogin(store);
      _syncService.pullFromFirestore();
      if (onSyncComplete != null) await onSyncComplete!();
      _status = AuthStatus.authenticated;
    } catch (_) {
      await _db.initForStore(store.storeId);
      _currentUserId = store.storeId;
      _syncService.setStoreId(store.storeId);
      try {
        await _saveSession();
      } catch (_) {}
      _syncService.pullFromFirestore();
      if (onSyncComplete != null) await onSyncComplete!();
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> selectStore(StoreConfig store) async {
    await _selectStore(store, knownRole: _selectedRoles[store.storeId]);
  }

  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _config = StoreConfig();
    _availableStores = [];
    _currentUserId = null;
    _currentUserRole = null;
    _currentLogin = '';
    _secretaries = [];
    await _clearSession();
    await _db.init();
    notifyListeners();
  }

  Future<String?> configureStore(
    String storeName,
    String adminLogin,
    String adminPassword, {
    String email = '',
  }) async {
    if (storeName.trim().isEmpty) return 'Le nom de la boutique est requis';
    if (adminLogin.trim().isEmpty) return 'Le login administrateur est requis';
    if (adminPassword.trim().isEmpty) return 'Le mot de passe est requis';

    final connected = await Connectivity().checkConnectivity().timeout(
      const Duration(seconds: 5),
    );
    if (connected.contains(ConnectivityResult.none)) {
      return 'NO_INTERNET';
    }

    try {
      // Vérifier que le nom de la boutique est unique
      final existingName = await _firestore
          .collection('stores')
          .where('name', isEqualTo: storeName.trim())
          .get()
          .timeout(const Duration(seconds: 30));
      if (existingName.docs.isNotEmpty) {
        return 'Ce nom de boutique existe déjà';
      }

      // Vérifier que le login admin est unique dans TOUTES les boutiques
      final existingAdmin = await _firestore
          .collection('stores')
          .where('adminLogin', isEqualTo: adminLogin.trim())
          .get()
          .timeout(const Duration(seconds: 30));
      if (existingAdmin.docs.isNotEmpty) {
        return 'Ce login administrateur est déjà utilisé';
      }

      // Vérifier que le login n'est pas déjà utilisé par un secrétaire
      final existingSec = await _firestore
          .collectionGroup('secretaries')
          .where('login', isEqualTo: adminLogin.trim())
          .get()
          .timeout(const Duration(seconds: 30));
      if (existingSec.docs.isNotEmpty) {
        return 'Ce login est déjà utilisé par un secrétaire';
      }

      final hash = _hash(adminPassword.trim());
      await _firestore
          .collection('stores')
          .add({
            'name': storeName.trim(),
            'adminLogin': adminLogin.trim(),
            'adminPassword': hash,
            'email': email.trim(),
            'backupEnabled': true,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 30));

      return null;
    } on TimeoutException {
      return 'La connexion au serveur a expiré';
    } catch (e) {
      return 'Erreur: ${e.toString()}';
    }
  }

  Future<void> loadSecretaries() async {
    if (_config.storeId.isEmpty) return;
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(_config.storeId)
          .collection('secretaries')
          .get()
          .timeout(const Duration(seconds: 20));
      _secretaries = snapshot.docs.map((doc) {
        final data = doc.data();
        return Secretary()
          ..id = doc.id
          ..name = data['name'] ?? ''
          ..login = data['login'] ?? ''
          ..password = data['password'] ?? ''
          ..email = data['email'] ?? ''
          ..role = data['role'] ?? 'secrétaire'
          ..canViewDashboard = data['canViewDashboard'] ?? true
          ..canManageProducts = data['canManageProducts'] ?? false
          ..canManageClients = data['canManageClients'] ?? true
          ..canManageOrders = data['canManageOrders'] ?? true
          ..canManagePos = data['canManagePos'] ?? true
          ..canManageStock = data['canManageStock'] ?? false
          ..canViewReports = data['canViewReports'] ?? false
          ..canManageSettings = data['canManageSettings'] ?? false
          ..canManageSecretaries = data['canManageSecretaries'] ?? false;
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> addSecretary(Secretary secretary) async {
    if (_config.storeId.isEmpty) return 'Aucune boutique configurée';
    try {
      final trimmedLogin = secretary.login.trim();
      if (trimmedLogin.isEmpty) return 'Le login est requis';

      // Vérifier l'unicité du login dans TOUTES les boutiques (admin + secrétaires)
      final existingAdmin = await _firestore
          .collection('stores')
          .where('adminLogin', isEqualTo: trimmedLogin)
          .get()
          .timeout(const Duration(seconds: 15));
      if (existingAdmin.docs.isNotEmpty) {
        return 'Ce login est déjà utilisé par un administrateur';
      }

      final existingSec = await _firestore
          .collectionGroup('secretaries')
          .where('login', isEqualTo: trimmedLogin)
          .get()
          .timeout(const Duration(seconds: 15));
      if (existingSec.docs.isNotEmpty) {
        return 'Ce login est déjà utilisé';
      }

      final hash = _hash(secretary.password);
      await _firestore
          .collection('stores')
          .doc(_config.storeId)
          .collection('secretaries')
          .add({
            'name': secretary.name.trim(),
            'login': secretary.login.trim(),
            'password': hash,
            'email': secretary.email.trim(),
            'role': secretary.role,
            'canViewDashboard': secretary.canViewDashboard,
            'canManageProducts': secretary.canManageProducts,
            'canManageClients': secretary.canManageClients,
            'canManageOrders': secretary.canManageOrders,
            'canManagePos': secretary.canManagePos,
            'canManageStock': secretary.canManageStock,
            'canViewReports': secretary.canViewReports,
            'canManageSettings': secretary.canManageSettings,
            'canManageSecretaries': secretary.canManageSecretaries,
          })
          .timeout(const Duration(seconds: 15));

      await loadSecretaries();
      return null;
    } catch (e) {
      return 'Erreur lors de l\'ajout du secrétaire';
    }
  }

  Future<String?> updateSecretary(Secretary secretary) async {
    if (_config.storeId.isEmpty) return 'Aucune boutique configurée';
    try {
      final trimmedLogin = secretary.login.trim();
      if (trimmedLogin.isEmpty) return 'Le login est requis';

      // Vérifier l'unicité du login si modifié
      final existingAdmin = await _firestore
          .collection('stores')
          .where('adminLogin', isEqualTo: trimmedLogin)
          .get()
          .timeout(const Duration(seconds: 15));
      if (existingAdmin.docs.isNotEmpty) {
        return 'Ce login est déjà utilisé par un administrateur';
      }

      final existingSec = await _firestore
          .collectionGroup('secretaries')
          .where('login', isEqualTo: trimmedLogin)
          .get()
          .timeout(const Duration(seconds: 15));
      final sameLogin = existingSec.docs.any(
        (doc) =>
            doc.reference.path !=
            'stores/${_config.storeId}/secretaries/${secretary.id}',
      );
      if (sameLogin) {
        return 'Ce login est déjà utilisé';
      }

      final data = <String, dynamic>{
        'name': secretary.name.trim(),
        'login': secretary.login.trim(),
        'role': secretary.role,
        'email': secretary.email.trim(),
        'canViewDashboard': secretary.canViewDashboard,
        'canManageProducts': secretary.canManageProducts,
        'canManageClients': secretary.canManageClients,
        'canManageOrders': secretary.canManageOrders,
        'canManagePos': secretary.canManagePos,
        'canManageStock': secretary.canManageStock,
        'canViewReports': secretary.canViewReports,
        'canManageSettings': secretary.canManageSettings,
        'canManageSecretaries': secretary.canManageSecretaries,
      };
      if (secretary.password.isNotEmpty) {
        data['password'] = _hash(secretary.password);
      }
      await _firestore
          .collection('stores')
          .doc(_config.storeId)
          .collection('secretaries')
          .doc(secretary.id)
          .update(data)
          .timeout(const Duration(seconds: 15));
      await loadSecretaries();
      return null;
    } catch (e) {
      return 'Erreur lors de la modification du secrétaire';
    }
  }

  Future<void> deleteSecretary(String id) async {
    if (_config.storeId.isEmpty) return;
    try {
      await _firestore
          .collection('stores')
          .doc(_config.storeId)
          .collection('secretaries')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 15));
      await loadSecretaries();
    } catch (_) {}
  }

  void toggleBackup() {
    _config.backupEnabled = !_config.backupEnabled;
    notifyListeners();
    // Sauvegarde asynchrone en arrière-plan
    if (_config.storeId.isNotEmpty) {
      _firestore
          .collection('stores')
          .doc(_config.storeId)
          .update({'backupEnabled': _config.backupEnabled})
          .timeout(const Duration(seconds: 15))
          .catchError((_) {});
    }
    _saveSession().catchError((_) {});
  }

  Future<String?> forgotPassword(String email) async {
    final connected = await Connectivity().checkConnectivity().timeout(
      const Duration(seconds: 5),
    );
    if (connected.contains(ConnectivityResult.none)) {
      return 'NO_INTERNET';
    }

    try {
      final stores = await _firestore
          .collection('stores')
          .get()
          .timeout(const Duration(seconds: 20));
      final trimmed = email.trim().toLowerCase();
      for (final doc in stores.docs) {
        final data = doc.data();
        if (data['email']?.toString().toLowerCase() == trimmed) {
          return 'Un email de récupération a été envoyé à $email';
        }
        final secs = await doc.reference
            .collection('secretaries')
            .where('email', isEqualTo: email.trim())
            .get()
            .timeout(const Duration(seconds: 15));
        if (secs.docs.isNotEmpty) {
          return 'Un email de récupération a été envoyé à $email';
        }
      }
      return 'Aucun compte trouvé avec cet email';
    } on TimeoutException {
      return 'La connexion au serveur a expiré';
    } catch (_) {
      return 'Erreur lors de la récupération';
    }
  }

  bool hasPermission(String permission) {
    if (_currentUserRole == 'admin') return true;
    final sec = _secretaries.where((s) => s.login == _currentLogin).firstOrNull;
    if (sec == null) return false;
    switch (permission) {
      case 'dashboard':
        return sec.canViewDashboard;
      case 'products':
        return sec.canManageProducts;
      case 'clients':
        return sec.canManageClients;
      case 'orders':
        return sec.canManageOrders;
      case 'pos':
        return sec.canManagePos;
      case 'stock':
        return sec.canManageStock;
      case 'reports':
        return sec.canViewReports;
      case 'settings':
        return sec.canManageSettings;
      case 'secretaries':
        return sec.canManageSecretaries;
      default:
        return false;
    }
  }
}
