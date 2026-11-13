import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:sembast/sembast.dart';

typedef SyncRow = Map<String, Object?>;

Object? canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: canonical(value[key])};
  }
  if (value is List) return value.map(canonical).toList();
  return value;
}

SyncRow event(String kind, SyncRow data) {
  final id = sha256
      .convert(utf8.encode(jsonEncode(canonical({'kind': kind, 'data': data}))))
      .toString();
  return {'id': id, 'kind': kind, 'data': data};
}

class SyncPage {
  SyncPage(this.ack, this.rows, this.cursor, this.more);
  final List<String> ack;
  final List<SyncRow> rows;
  final int cursor;
  final bool more;
}

abstract class SyncRemote {
  String get owner;
  Future<SyncPage> exchange(List<SyncRow> events, int cursor);
}

class SupabaseRemote implements SyncRemote {
  SupabaseRemote(this.base, this.key, this.token, this.owner);
  final Uri base;
  final String key, token;
  @override
  final String owner;
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publicKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get configured => url.isNotEmpty && publicKey.isNotEmpty;

  static Future<SupabaseRemote> login(String email, String password) async {
    final base = Uri.parse(url);
    if (base.scheme != 'https' || !base.hasAuthority) {
      throw StateError('Se requiere un servicio HTTPS.');
    }
    final response = await http
        .post(
          base.resolve('/auth/v1/token?grant_type=password'),
          headers: {'apikey': publicKey, 'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError(
        'No se pudo iniciar sesión. Comprueba tus datos y la conexión.',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return SupabaseRemote(
      base,
      publicKey,
      body['access_token'] as String,
      body['user']['id'] as String,
    );
  }

  @override
  Future<SyncPage> exchange(List<SyncRow> events, int cursor) async {
    final response = await http
        .post(
          base.resolve('/rest/v1/rpc/trama_exchange'),
          headers: {
            'apikey': key,
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'batch': events, 'after_seq': cursor}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      throw StateError('La sesión ha caducado. Vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200) {
      throw StateError('La sincronización no ha terminado. Puedes reintentar.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return SyncPage(
      List<String>.from(body['ack']),
      List<SyncRow>.from(body['events']),
      body['cursor'] as int,
      body['more'] as bool,
    );
  }
}

class SyncEngine {
  SyncEngine(this.db);
  final Database db;
  final state = stringMapStoreFactory.store('cloud_state_v1');
  final seen = stringMapStoreFactory.store('cloud_seen_v1');
  final sessions = stringMapStoreFactory.store('sessions');
  final reviews = stringMapStoreFactory.store('review_attempts_v1');
  bool _running = false;

  Future<List<SyncRow>> pending() async {
    final outgoing = <SyncRow>[];
    for (final row in await sessions.find(db)) {
      final e = event('session', {...row.value, 'id': row.key});
      if (!await seen.record(e['id'] as String).exists(db)) outgoing.add(e);
    }
    for (final row in await reviews.find(db)) {
      final e = event('review', row.value);
      if (!await seen.record(e['id'] as String).exists(db)) outgoing.add(e);
    }
    return outgoing;
  }

  Future<void> sync(SyncRemote remote) async {
    if (_running) throw StateError('Ya hay una sincronización en curso.');
    _running = true;
    try {
      // A local notebook is bound once. Another account must use a separate
      // browser profile, preventing accidental uploads to someone else's account.
      await db.transaction((txn) async {
        final binding = await state.record('binding').get(txn);
        if (binding != null && binding['owner'] != remote.owner) {
          throw StateError(
            'Este cuaderno pertenece a otra cuenta. Usa otro perfil del navegador.',
          );
        }
        await state.record('binding').put(txn, {'owner': remote.owner});
      });
      var more = true;
      while (more) {
        final batch = (await pending()).take(50).toList();
        final saved = await state.record('cursor').get(db);
        final cursor = (saved?['value'] as int?) ?? 0;
        final page = await remote.exchange(batch, cursor);
        if ((page.more && page.cursor == cursor) ||
            page.cursor < cursor ||
            batch.any((e) => !page.ack.contains(e['id']))) {
          throw StateError('Acuse de sincronización incompleto.');
        }
        await db.transaction((txn) async {
          for (final e in page.rows) {
            final id = e['id'] as String;
            final kind = e['kind'] as String;
            final data = Map<String, Object?>.from(e['data'] as Map);
            if (event(kind, data)['id'] != id) {
              throw StateError('Evento inválido.');
            }
            if (await seen.record(id).exists(txn)) continue;
            if (kind == 'session') {
              final sessionId = data.remove('id') as String;
              final existing = await sessions.record(sessionId).get(txn);
              if (existing != null &&
                  jsonEncode(canonical(existing)) !=
                      jsonEncode(canonical(data))) {
                throw StateError(
                  'Hay dos versiones de una sesión. Se conserva la copia local.',
                );
              }
              await sessions.record(sessionId).put(txn, data);
            } else if (kind == 'review') {
              // Preserve simultaneous attempts as independent evidence.
              final already = (await reviews.find(txn))
                  .any((r) => event('review', r.value)['id'] == id);
              if (!already) await reviews.record(id).put(txn, data);
            } else {
              throw StateError('Tipo de evento desconocido.');
            }
            await seen.record(id).put(txn, {});
          }
          for (final id in page.ack) {
            await seen.record(id).put(txn, {});
          }
          await state.record('cursor').put(txn, {'value': page.cursor});
          await state.record('last').put(txn, {
            'time': DateTime.now().toUtc().toIso8601String(),
          });
        });
        more = page.more || (await pending()).isNotEmpty;
      }
    } finally {
      _running = false;
    }
  }
}
