import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:trama/data/journal.dart';
import 'package:trama/lessons.dart';
import 'package:trama/main.dart';
import 'package:trama/review.dart';

void main() {
  final lesson = lessons.firstWhere((lesson) => lesson.id == 'ac');
  var now = DateTime.utc(2026, 11, 4, 10);
  late Database db;
  late Journal journal;
  setUp(() async {
    now = DateTime.utc(2026, 11, 4, 10);
    db = await databaseFactoryMemory.openDatabase(
      'test-${DateTime.now().microsecondsSinceEpoch}',
    );
    journal = Journal(db, clock: () => now);
  });
  tearDown(() => db.close());
  Future<void> complete(String id) async {
    for (final (i, q) in lesson.questions.indexed) {
      await journal.confirm(id, lesson, i, '${q.answer}');
    }
  }

  Future<ReviewPlan> plan() async => ReviewPlan.fromHistory(
    lesson.id,
    await journal.history(),
    await journal.reviewHistory(),
  )!;

  test('las confirmaciones son atómicas y una pestaña antigua no pisa la evidencia', () async {
    await journal.confirm('s', lesson, 0, '2');
    final reopened = Journal(db);
    final draft = (await reopened.unfinished())['ac']!;
    expect(draft['id'], 's');
    expect((draft['answers'] as List).first['correct'], false);
    await expectLater(
      reopened.confirm('other', lesson, 1, '0'),
      throwsStateError,
    );
    await expectLater(reopened.confirm('s', lesson, 0, '0'), throwsStateError);
    await reopened.confirm('s', lesson, 1, '1');
    await reopened.confirm('s', lesson, 2, '2');
    await expectLater(reopened.confirm('s', lesson, 2, '2'), throwsStateError);
    expect(await reopened.unfinished(), isEmpty);
    expect(await reopened.history(), hasLength(1));
    expect((await reopened.history()).first['answers'], hasLength(3));
  });

  test(
    'historial anterior al cambio conserva fecha, XP y repaso pendiente',
    () async {
      final start = now.subtract(const Duration(days: 3));
      await journal.entries.record('legacy').put(db, {
        'version': 1,
        'lesson': 'ac',
        'answers': [],
        'time': start.toIso8601String(),
      });
      await complete('new');
      expect((await plan()).due, start.add(const Duration(days: 1)));
      expect((await plan()).ready(now), isTrue);
      expect(
        (await journal.history()).map((row) => row['lesson']).toSet().length,
        1,
      );
    },
  );

  test(
    'espera 24 h; un acierto amplía el intervalo y un fallo vuelve a un día',
    () async {
      await complete('s');
      now = now.add(const Duration(hours: 23, minutes: 59));
      await expectLater(journal.recordReview('ac', 0, '0'), throwsStateError);
      now = now.add(const Duration(minutes: 1));
      for (final (i, gap) in [3, 7, 14, 14].indexed) {
        final q = reviewQuestion('ac', i);
        await journal.recordReview('ac', i, '${q.answer}');
        await expectLater(
          journal.recordReview('ac', i, '${q.answer}'),
          throwsStateError,
        );
        expect((await plan()).due, now.add(Duration(days: gap)));
        expect((await plan()).lastCorrect, true);
        now = now.add(Duration(days: gap));
      }
      final q = reviewQuestion('ac', 4);
      await journal.recordReview(
        'ac',
        4,
        '${(q.answer + 1) % q.choices.length}',
      );
      expect((await plan()).due, now.add(const Duration(days: 1)));
      expect((await plan()).lastCorrect, false);
    },
  );

  test(
    'las tres materias tienen variantes verificables diferentes del ensayo',
    () {
      for (final l in lessons) {
        final seen = <String>{};
        for (var round = 0; round < 5; round++) {
          final q = reviewQuestion(l.id, round);
          expect(seen.add(q.prompt), true);
          expect(
            q.prompt,
            isNot(reviewQuestion(l.id, round, preview: true).prompt),
          );
          expect(grade(q, '${q.answer}').correct, true);
          expect(q.choices.toSet().length, q.choices.length);
        }
      }
    },
  );

  testWidgets(
    'reanuda en la tercera pregunta y un ensayo libre no acredita recuerdo',
    (t) async {
      await t.runAsync(() async {
        await journal.select({'ac'});
        await journal.confirm('saved', lesson, 0, '0');
        await journal.confirm('saved', lesson, 1, '1');
      });
      Future<void> tap(String label) async {
        final target = find.text(label).last;
        await t.ensureVisible(target);
        await t.pumpAndSettle();
        await t.tap(target);
        await t.pumpAndSettle();
      }

      await t.pumpWidget(Trama(journal));
      await t.pumpAndSettle();
      await tap('Continuar donde lo dejaste');
      expect(find.text('PRÁCTICA · 3 DE 3'), findsOneWidget);
      await tap('1');
      await tap('Comprobar');
      await tap('Ver resultados');
      await tap('Volver al cuaderno');
      await tap('Ensayar una variante');
      final preview = reviewQuestion('ac', 0, preview: true);
      await tap(preview.choices[preview.answer]);
      await tap('Comprobar');
      await tap('Volver al cuaderno');
      expect(await t.runAsync(journal.reviewHistory), isEmpty);
      now = now.add(const Duration(days: 1));
      // Reopening the app recomputes the queue from persisted sessions.
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await t.pumpWidget(Trama(journal));
      await t.pumpAndSettle();
      await tap('Variante pendiente');
      final q = reviewQuestion('ac', 0);
      await tap(q.choices[q.answer]);
      await tap('Comprobar');
      await tap('Volver al cuaderno');
      await tap('Mi progreso');
      expect(
        find.textContaining('Recordado en el último repaso'),
        findsOneWidget,
      );
      expect(find.textContaining('10 XP'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
}
