import 'package:sembast_web/sembast_web.dart';

Future<Database> openLocal() => databaseFactoryWeb.openDatabase('trama.v1');
