import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast/sembast_io.dart';
import 'package:trama/catalog_source.dart' as source;
import 'package:trama/data/content.dart';
import 'package:trama/data/journal.dart';
import 'package:trama/data/sync.dart';
import 'package:trama/lessons.dart';
import 'package:trama/review.dart';

class Reply implements SyncRemote {
  Reply(this.response);
  final SyncPage response;
  @override
  String get owner => 'test-account';
  @override
  Future<SyncPage> exchange(List<SyncRow> events, int cursor) async => response;
}

void main() {
  test('cada paquete reproduce íntegramente el modelo editorial', () async {
    final db = await databaseFactoryMemory.openDatabase('package-model');
    final store = LessonStore(db);
    for (final expected in source.lessons) {
      final actual = store.decode(
        expected.id,
        File('content/${expected.id}.v1.json').readAsBytesSync(),
      );
      expect(
        [actual.subject, actual.title, actual.goal, actual.example],
        [expected.subject, expected.title, expected.goal, expected.example],
      );
      for (final (i, q) in actual.questions.indexed) {
        final original = expected.questions[i];
        expect(
          [q.prompt, q.choices, q.answer, q.feedback],
          [
            original.prompt,
            original.choices,
            original.answer,
            original.feedback,
          ],
        );
      }
    }
    await db.close();
  });
  test('una descarga truncada no instala contenido parcial', () async {
    final db = await databaseFactoryMemory.openDatabase('truncated');
    final metadata = lessons.firstWhere((l) => l.id == 'fp.sum');
    final bytes = File('content/fp.sum.v1.json').readAsBytesSync();
    final store = LessonStore(
      db,
      fetch: (_) async => bytes.sublist(0, bytes.length - 1),
    );
    await expectLater(store.download(metadata), throwsFormatException);
    expect(await store.installed(), isEmpty);
    await db.close();
  });
  test('la identidad de un evento ignora el orden de las claves pero detecta cambios', () {
    expect(
      event('review', {
        'a': 1,
        'b': {'x': 2, 'y': 3},
      })['id'],
      event('review', {
        'b': {'y': 3, 'x': 2},
        'a': 1,
      })['id'],
    );
    expect(
      event('review', {'answer': '1'})['id'],
      isNot(event('review', {'answer': '2'})['id']),
    );
    expect(
      event('review', {'answer': '1'})['id'],
      isNot(event('session', {'answer': '1'})['id']),
    );
  });
  test('repaso converge independientemente del orden de llegada y de la zona horaria', () {
    final sessions = <JournalRow>[
      {'lesson': 'ac', 'time': '2026-11-01T00:00:00Z'},
    ];
    final reviews = <JournalRow>[
      {
        'lesson': 'ac',
        'round': 0,
        'time': '2026-11-02T00:00:00Z',
        'answer': '2',
        'correct': true,
      },
      {
        'lesson': 'ac',
        'round': 0,
        'time': '2026-11-02T01:01:00+01:00',
        'answer': '1',
        'correct': false,
      },
      {
        'lesson': 'ac',
        'round': 1,
        'time': '2026-11-05T00:00:00Z',
        'answer': '0',
        'correct': true,
      },
    ];
    final expected = ReviewPlan.fromHistory('ac', sessions, reviews)!;
    for (var shift = 0; shift < 3; shift++) {
      final reordered = [
        ...reviews.skip(shift),
        ...reviews.take(shift),
      ].reversed.toList();
      final plan = ReviewPlan.fromHistory('ac', sessions, reordered)!;
      expect(
        [plan.round, plan.streak, plan.due],
        [expected.round, expected.streak, expected.due],
      );
    }
    expect(expected.due, DateTime.utc(2026, 11, 12));
  });
  test('acuse incompleto conserva el envío pendiente y el cursor', () async {
    final db = await databaseFactoryMemory.openDatabase('no-ack');
    final journal = Journal(db);
    final l = lessons.firstWhere((l) => l.id == 'ac');
    for (final (i, q) in l.questions.indexed) {
      await journal.confirm('s', l, i, '${q.answer}');
    }
    final engine = SyncEngine(db);
    await expectLater(
      engine.sync(Reply(SyncPage([], [], 0, false))),
      throwsStateError,
    );
    expect(await engine.pending(), hasLength(1));
    expect(await engine.state.record('cursor').get(db), isNull);
    await expectLater(
      engine.sync(Reply(SyncPage([], [], 0, true))),
      throwsStateError,
    );
    await db.close();
  });
  test(
    'borrador y paquete sobreviven al cierre real de la base nativa',
    () async {
      final temp = await Directory.systemTemp.createTemp('trama-persistence-');
      final file = '${temp.path}/journal.db';
      var db = await databaseFactoryIo.openDatabase(file);
      final meta = lessons.firstWhere((l) => l.id == 'fp.sum');
      final j = Journal(
        db,
        fetch: (_) async => File('content/fp.sum.v1.json').readAsBytesSync(),
      );
      final l = await j.content.download(meta);
      await j.confirm('saved', l, 0, '1');
      await j.select({'fp'});
      await db.close();
      db = await databaseFactoryIo.openDatabase(file);
      final reopened = Journal(
        db,
        fetch: (_) async => throw StateError('offline'),
      );
      expect((await reopened.content.open(meta)).questions, hasLength(3));
      expect((await reopened.unfinished())['fp.sum']!['id'], 'saved');
      expect(await reopened.selected(), {'fp'});
      expect(jsonEncode(await reopened.history()), '[]');
      await db.close();
      await temp.delete(recursive: true);
    },
  );
}
