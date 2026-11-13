import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:trama/data/content.dart';
import 'package:trama/data/journal.dart';
import 'package:trama/data/sync.dart';
import 'package:trama/lessons.dart';
import 'package:trama/review.dart';

class MemoryRemote implements SyncRemote {
  @override
  String owner = 'pilot';
  final rows = <SyncRow>[];
  bool loseResponse = false;
  @override
  Future<SyncPage> exchange(List<SyncRow> events, int cursor) async {
    for (final e in events) {
      if (!rows.any((r) => r['id'] == e['id'])) rows.add(e);
    }
    if (loseResponse) {
      loseResponse = false;
      throw const SocketException('response lost after commit');
    }
    final page = rows.skip(cursor).take(2).toList();
    return SyncPage(
      events.map((e) => e['id'] as String).toList(),
      page,
      cursor + page.length,
      cursor + page.length < rows.length,
    );
  }
}

void main() {
  late Database a, b;
  setUp(() async {
    a = await databaseFactoryMemory.openDatabase(
      'a-${DateTime.now().microsecondsSinceEpoch}',
    );
    b = await databaseFactoryMemory.openDatabase(
      'b-${DateTime.now().microsecondsSinceEpoch}',
    );
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });
  final entry = lessons.firstWhere((l) => l.id == 'ac');
  Future<void> complete(Journal j, String id) async {
    for (final (i, q) in entry.questions.indexed) {
      await j.confirm(id, entry, i, '${q.answer}');
    }
  }

  test(
    'descarga íntegra; quitar contenido conserva historial y borrador',
    () async {
      final meta = lessons.firstWhere((l) => l.id == 'fp.sum');
      final bytes = File('content/${meta.id}.v1.json').readAsBytesSync();
      var network = true;
      final j = Journal(
        a,
        fetch: (_) async {
          if (!network) throw const SocketException('offline');
          return bytes;
        },
      );
      await expectLater(j.content.open(meta), throwsStateError);
      final full = await j.content.download(meta);
      expect(full.questions, hasLength(3));
      await j.confirm('draft', full, 0, '1');
      await complete(j, 'completed');
      network = false;
      expect((await j.content.open(meta)).example, isNotEmpty);
      await j.content.remove(meta.id);
      expect(await j.history(), hasLength(1));
      expect((await j.unfinished())[meta.id]!['id'], 'draft');
      await expectLater(
        j.content.download(meta),
        throwsA(isA<SocketException>()),
      );
      expect(await j.content.installed(), isEmpty);
      network = true;
      await j.content.download(meta);
      expect((await j.unfinished())[meta.id]!['answers'], hasLength(1));
      final corrupt = LessonStore(a, fetch: (_) async => [...bytes]..[0] = 0);
      await expectLater(corrupt.download(meta), throwsFormatException);
      expect((await j.content.open(meta)).questions, hasLength(3));
    },
  );

  test(
    'los nueve paquetes coinciden con su versión y las entradas no usan red',
    () async {
      final store = LessonStore(
        a,
        fetch: (id) async => File('content/$id.v1.json').readAsBytesSync(),
      );
      for (final l in lessons.where((l) => l.questions.isEmpty)) {
        expect((await store.download(l)).questions, hasLength(3));
      }
      final offline = LessonStore(
        a,
        fetch: (_) async => throw StateError('network'),
      );
      for (final l in lessons) {
        expect((await offline.open(l)).questions, hasLength(3));
      }
    },
  );

  test(
    'reintento tras respuesta perdida, paginación y dos cuadernos convergen',
    () async {
      final ja = Journal(a), jb = Journal(b);
      final cloud = MemoryRemote()..loseResponse = true;
      final sa = SyncEngine(a), sb = SyncEngine(b);
      for (var i = 0; i < 4; i++) {
        await complete(ja, 'a$i');
      }
      await complete(jb, 'b');
      await expectLater(sa.sync(cloud), throwsA(isA<SocketException>()));
      expect(await sa.pending(), hasLength(4));
      await sa.sync(cloud);
      await sb.sync(cloud);
      await sa.sync(cloud);
      await sb.sync(cloud);
      expect(await ja.history(), hasLength(5));
      expect(await jb.history(), hasLength(5));
      expect(cloud.rows, hasLength(5));
      expect(await sa.pending(), isEmpty);
      expect(await sb.pending(), isEmpty);
      cloud.owner = 'someone-else';
      await expectLater(sa.sync(cloud), throwsStateError);
      expect(cloud.rows, hasLength(5));
    },
  );

  test(
    'repasos paralelos se conservan sin duplicar el intervalo espaciado',
    () async {
      var time = DateTime.utc(2026, 11, 1);
      final ja = Journal(a, clock: () => time),
          jb = Journal(b, clock: () => time);
      final sa = SyncEngine(a), sb = SyncEngine(b), cloud = MemoryRemote();
      await complete(ja, 'start');
      await sa.sync(cloud);
      await sb.sync(cloud);
      time = time.add(const Duration(days: 1));
      final answer = '${reviewQuestion('ac', 0).answer}';
      await ja.recordReview('ac', 0, answer);
      time = time.add(const Duration(minutes: 1));
      await jb.recordReview('ac', 0, answer);
      await sb.sync(cloud);
      await sa.sync(cloud);
      await sb.sync(cloud);
      final pa = ReviewPlan.fromHistory(
        'ac',
        await ja.history(),
        await ja.reviewHistory(),
      )!;
      final pb = ReviewPlan.fromHistory(
        'ac',
        await jb.history(),
        await jb.reviewHistory(),
      )!;
      expect(await ja.reviewHistory(), hasLength(2));
      expect(await jb.reviewHistory(), hasLength(2));
      expect(pa.round, 1);
      expect(pa.streak, 1);
      expect(pa.due, DateTime.utc(2026, 11, 5));
      expect(pb.due, pa.due);
    },
  );

  test('paquete remoto corrupto revierte importación y cursor', () async {
    final cloud = MemoryRemote();
    cloud.rows.add({
      'id': 'invalid',
      'kind': 'session',
      'data': {'id': 'bad'},
    });
    final sync = SyncEngine(a);
    await expectLater(sync.sync(cloud), throwsStateError);
    expect(await Journal(a).history(), isEmpty);
    expect(await sync.state.record('cursor').get(a), isNull);
  });
}
