import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';

Future<Database> openLocal() async {
  final dir = await getApplicationSupportDirectory();
  return databaseFactoryIo.openDatabase('${dir.path}/trama.db');
}
