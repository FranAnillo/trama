import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:trama/data/journal.dart';
import 'package:trama/diagnostic.dart';
import 'package:trama/catalog_source.dart';
import 'package:trama/main.dart';
import 'package:trama/review.dart';

void main() {
  test('tres rutas, doce lecciones y 36 ejercicios con identidad propia', () {
    expect(entryLessons.map((l) => l.id), ['fp', 'rc', 'ac']);
    expect(lessons.map((l) => l.id).toSet(), hasLength(12));
    for (final entry in entryLessons) {
      final route = subjectRoute(entry.id);
      expect(route, hasLength(4));
      expect(route.first.id, entry.id);
      expect(
        route.every(
          (l) => l.questions.length == 3 && l.subject == entry.subject,
        ),
        true,
      );
      final keys = diagnosticProbes[entry.id]!.map((q) => q.answer).toList();
      expect(placementIndex(entry.id, keys), 3);
      for (var i = 0; i < 3; i++) {
        final partial = <int?>[...keys];
        partial[i] = null;
        expect(placementIndex(entry.id, partial), i);
        partial[i] = (keys[i] + 1) % 3;
        expect(placementIndex(entry.id, partial), i);
      }
    }
  });

  test('las claves del nuevo contenido y sus primeras variantes corresponden a las soluciones revisables', () {
    const expected = {
      'fp.sum': [1, 2, 0],
      'fp.find': [0, 1, 2],
      'fp.func': [1, 2, 0],
      'rc.prefix': [1, 2, 1],
      'rc.port': [1, 2, 2],
      'rc.ttl': [1, 1, 2],
      'ac.block': [1, 0, 2],
      'ac.line': [1, 2, 0],
      'ac.time': [2, 0, 1],
    };
    const firstReview = {
      'fp.sum': '8',
      'fp.find': '0',
      'fp.func': '14',
      'rc.prefix': '10.0.0.0',
      'rc.port': '50000',
      'rc.ttl': '2',
      'ac.block': '1',
      'ac.line': '1',
      'ac.time': '4 ns',
    };
    for (final l in additionalLessons) {
      expect(l.questions.map((q) => q.answer), expected[l.id]);
      final review = reviewQuestion(l.id, 0);
      expect(review.choices[review.answer], firstReview[l.id]);
    }
  });

  test(
    'las recomendaciones respetan lo empezado y permiten avanzar al completar',
    () {
      final route = subjectRoute('fp');
      expect(nextLesson(route, null, {}, <String>{}).id, 'fp');
      expect(nextLesson(route, 'fp.find', {}, <String>{}).id, 'fp.find');
      expect(
        nextLesson(route, 'fp.find', {'fp.find'}, <String>{}).id,
        'fp.func',
      );
      expect(nextLesson(route, 'fp.find', {}, {'fp.sum'}).id, 'fp.sum');
    },
  );

  test(
    'diagnosticar conserva las materias antiguas y no crea sesiones ni repasos',
    () async {
      final db = await databaseFactoryMemory.openDatabase('placement');
      final j = Journal(db);
      await j.select({'ac', 'rc'});
      await j.savePlacement('ac', [1, 0, 2]);
      await j.savePlacement('rc', [null, null, null]);
      expect(await Journal(db).placements(), {'ac': 'ac.time', 'rc': 'rc'});
      await j.savePlacement('ac', [1, null, 2]);
      expect(await Journal(db).placements(), {'ac': 'ac.block', 'rc': 'rc'});
      expect(await j.selected(), {'ac', 'rc'});
      expect(await j.history(), isEmpty);
      expect(await j.reviewHistory(), isEmpty);
      expect(await j.unfinished(), isEmpty);
      await db.close();
    },
  );

  testWidgets(
    'diagnóstico opcional, salto y selección manual de otra lección',
    (t) async {
      final db = await t.runAsync(
        () => databaseFactoryMemory.openDatabase('placement-ui'),
      );
      final packages = {
        for (final id in ['rc.ttl', 'rc.prefix'])
          id: File('content/$id.v1.json').readAsBytesSync(),
      };
      final journal = Journal(db!, fetch: (id) async => packages[id]!);
      await t.runAsync(() => journal.select({'rc'}));
      await t.pumpWidget(Trama(journal));
      await t.pumpAndSettle();
      Future<void> tap(String label) async {
        final target = find.text(label).last;
        await t.ensureVisible(target);
        await t.pumpAndSettle();
        await t.tap(target);
        await t.pumpAndSettle();
      }

      await tap('Diagnóstico opcional');
      await tap('192.0.2.1');
      await tap('Siguiente pregunta');
      await tap('192.0.2.192');
      await tap('Siguiente pregunta');
      await tap('53001');
      await tap('Ver recomendación');
      expect(
        find.textContaining('Te recomendamos «Hasta dónde llega un paquete»'),
        findsOneWidget,
      );
      await tap('Abrir lección recomendada');
      await tap('Descargar y abrir');
      expect(find.text('PUNTO DE PARTIDA'), findsOneWidget);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await tap('Ver las 4 lecciones');
      await tap('2. Encontrar la red de una dirección');
      await tap('Descargar y abrir');
      expect(find.text('PUNTO DE PARTIDA'), findsOneWidget);
      expect(find.text('Encontrar la red de una dirección'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      addTearDown(db.close);
    },
  );
}
