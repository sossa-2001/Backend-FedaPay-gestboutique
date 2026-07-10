import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';

enum SyncStatus { syncing, completed, error, offline }

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  final AuthProvider? _authProvider;
  SyncStatus _status = SyncStatus.offline;
  DateTime? _lastSyncAt;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  SyncProvider(this._syncService, [this._authProvider]) {
    _initConnectivity();
  }

  SyncStatus get status => _status;
  DateTime? get lastSyncAt => _lastSyncAt;
  String get statusLabel {
    switch (_status) {
      case SyncStatus.syncing:
        return 'Synchronisation en cours…';
      case SyncStatus.completed:
        return 'Sauvegardé';
      case SyncStatus.error:
        return 'Erreur de synchronisation';
      case SyncStatus.offline:
        return 'Hors ligne';
    }
  }

  void _initConnectivity() {
    _subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (result.contains(ConnectivityResult.none)) {
        _status = SyncStatus.offline;
        notifyListeners();
      } else if (_status == SyncStatus.offline) {
        triggerSync();
      }
    });
  }

  Future<void> triggerSync() async {
    final authStoreId = _authProvider?.config.storeId ?? '';
    if (authStoreId.isNotEmpty) {
      _syncService.setStoreId(authStoreId);
    }

    if (!_syncService.isAvailable) {
      _status = SyncStatus.error;
      notifyListeners();
      return;
    }
    _status = SyncStatus.syncing;
    notifyListeners();
    try {
      await _syncService.syncAll();
      _lastSyncAt = DateTime.now();
      _status = SyncStatus.completed;
    } catch (_) {
      _status = SyncStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
