import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sembast/sembast.dart';

import '../lessons.dart';
import '../content_manifest.dart';

typedef ContentFetch = Future<List<int>> Function(String id);
const nativeContentOrigin = String.fromEnvironment('TRAMA_CONTENT_URL');

Future<List<int>> fetchContent(String id) async {
  final base = kIsWeb
      ? Uri.base.resolve('./')
      : Uri.tryParse(nativeContentOrigin);
  if (base == null || !base.hasAuthority) {
    throw StateError(
      'Falta configurar la dirección del contenido para esta plataforma.',
    );
  }
  final client = http.Client();
  try {
    final response = await client
        .send(http.Request('GET', base.resolve('content/$id.v1.json')))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('No se pudo descargar la unidad.');
    }
    final limit = contentManifest[id]!.bytes;
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 15),
    )) {
      bytes.addAll(chunk);
      if (bytes.length > limit) {
        throw const FormatException('El paquete supera el tamaño esperado.');
      }
    }
    return bytes;
  } finally {
    client.close();
  }
}

class LessonStore {
  LessonStore(this.db, {ContentFetch? fetch}) : fetch = fetch ?? fetchContent;
  final Database db;
  final ContentFetch fetch;
  final store = stringMapStoreFactory.store('content_v1');

  Future<Set<String>> installed() async =>
      (await store.find(db)).map((r) => r.key).toSet();

  Lesson decode(String id, List<int> data) {
    final expected = contentManifest[id]!;
    if (data.length != expected.bytes ||
        sha256.convert(data).toString() != expected.hash) {
      throw const FormatException(
        'La unidad recibida no coincide con la versión esperada.',
      );
    }
    final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    if (json['id'] != id || json['version'] != 1) {
      throw const FormatException('Versión incompatible.');
    }
    return Lesson(
      id,
      json['subject'] as String,
      json['title'] as String,
      json['goal'] as String,
      json['example'] as String,
      [
        for (final q in json['questions'] as List)
          Question(
            q['prompt'] as String,
            List<String>.from(q['choices']),
            q['answer'] as int,
            List<String>.from(q['feedback']),
          ),
      ],
    );
  }

  Future<Lesson> open(Lesson metadata) async {
    if (metadata.questions.isNotEmpty) return metadata;
    final saved = await store.record(metadata.id).get(db);
    if (saved != null) {
      return decode(metadata.id, utf8.encode(saved['body'] as String));
    }
    throw StateError('Descarga esta unidad para abrirla sin conexión.');
  }

  Future<Lesson> download(Lesson metadata) async {
    final bytes = await fetch(metadata.id);
    final lesson = decode(metadata.id, bytes);
    // Only a complete and verified package replaces the previous copy.
    await store.record(metadata.id).put(db, {'body': utf8.decode(bytes)});
    return lesson;
  }

  Future<void> remove(String id) => store.record(id).delete(db);
}
