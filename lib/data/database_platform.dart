import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';

DatabaseFactory get databaseFactory => databaseFactoryIo;

Future<String> databasePath({String? storeId}) async {
  final dir = await getApplicationDocumentsDirectory();
  final name = storeId != null ? 'gestbureau_$storeId.db' : 'gestbureau.db';
  return '${dir.path}/$name';
}
