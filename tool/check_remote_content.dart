import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:trama/content_manifest.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1)
    throw ArgumentError('Indica la URL pública del contenido.');
  final base = Uri.parse(
    args.single.endsWith('/') ? args.single : '${args.single}/',
  );
  for (final entry in contentManifest.entries) {
    final r = await http
        .get(base.resolve('content/${entry.key}.v1.json'))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200 ||
        r.bodyBytes.length != entry.value.bytes ||
        sha256.convert(r.bodyBytes).toString() != entry.value.hash) {
      stderr.writeln(
        'Paquete incompatible o inaccesible: ${entry.key}, HTTP ${r.statusCode}',
      );
      exitCode = 1;
      return;
    }
  }
  stdout.writeln(
    'PASS: las 12 unidades se descargan y verifican con el cliente HTTP de Dart.',
  );
}
