import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:trama/data/journal.dart';
import 'package:trama/catalog_source.dart';
import 'package:trama/main.dart';

void main() {
  test('el operador debe pasar todos los casos, incluido cero', () {
    final q = lessons.first.questions.first;
    expect(grade(q, ' >= ').correct, isTrue);
    for (final s in ['>', '<=', '<', '==', '!=', 'return 1', '']) {
      expect(grade(q, s).correct, isFalse);
    }
  });

  test(
    'todos los ítems de elección tienen una clave y feedback para cada opción',
    () {
      for (final l in lessons) {
        for (final q in l.questions.where((q) => q.choices.isNotEmpty)) {
          expect(q.feedback.length, q.choices.length);
          for (var i = 0; i < q.choices.length; i++) {
            expect(grade(q, '$i').correct, i == q.answer);
          }
          expect(grade(q, '-1').correct, isFalse);
        }
      }
    },
  );

  testWidgets('elegir materia, resolver, guardar y consultar progreso', (
    t,
  ) async {
    final db = await databaseFactoryMemory.openDatabase('journey');
    final journal = Journal(db);
    await t.pumpWidget(Trama(journal));
    await t.pumpAndSettle();
    Future<void> tap(String label) async {
      final target = find.text(label).last;
      await t.ensureVisible(target);
      await t.tap(target);
      await t.pumpAndSettle();
    }

    await t.tap(find.byTooltip('Cuenta y sincronización'));
    await t.pumpAndSettle();
    expect(
      find.text('Tu progreso se guarda en este dispositivo'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();
    await tap('Elegir mis materias');
    await tap('Fundamentos de Programación');
    await tap('Guardar');
    await tap('Abrir lección');
    await tap('Empezar práctica');
    await t.enterText(find.byType(TextField), '>=');
    await t.pump();
    await tap('Comprobar');
    expect(find.textContaining('cuatro pruebas pasan'), findsOneWidget);
    await tap('Continuar');
    await tap('x > 0');
    await tap('Comprobar');
    await tap('Continuar');
    await tap('1');
    await tap('Comprobar');
    await tap('Ver resultados');
    expect(find.text('3 de 3 respuestas correctas.'), findsOneWidget);
    await tap('Volver al cuaderno');
    await tap('Mi progreso');
    expect(find.textContaining('10 XP'), findsOneWidget);
    expect(await t.runAsync(journal.selected), {'fp'});
    await t.pumpWidget(const SizedBox());
    addTearDown(db.close);
  });
}
