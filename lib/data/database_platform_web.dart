import 'package:sembast_web/sembast_web.dart';

DatabaseFactory get databaseFactory => databaseFactoryWeb;

Future<String> databasePath({String? storeId}) async {
  return storeId != null ? 'gestbureau_$storeId.db' : 'gestbureau.db';
}
