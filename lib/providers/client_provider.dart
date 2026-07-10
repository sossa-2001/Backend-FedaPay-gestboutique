import 'package:flutter/material.dart';
import '../models/client.dart';
import '../data/database_service.dart';
import '../services/sync_service.dart';

class ClientProvider extends ChangeNotifier {
  final DatabaseService _db;
  final SyncService _sync;
  List<Client> _clients = [];
  bool _isLoading = false;

  ClientProvider(this._db, this._sync);

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;

  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();
    _clients = await _db.loadClients();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addClient(Client client) async {
    await _db.addClient(client);
    _sync.syncClient(client);
    await loadClients();
  }

  Future<void> updateClient(Client client) async {
    await _db.updateClient(client);
    _sync.syncClient(client);
    await loadClients();
  }

  Future<void> deleteClient(int id) async {
    await _db.deleteClient(id);
    _sync.deleteClient(id);
    await loadClients();
  }
}
