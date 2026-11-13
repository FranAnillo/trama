import 'lessons.dart';

/// Each probe addresses the route concept in the same position.
/// The last lesson is an integration task for students who pass all probes.
const diagnosticProbes = {
  'fp': [
    Question(
      'Un sensor cuenta valores no negativos en [0, −4, 0, 2]. ¿Cuántos cuenta?',
      ['1', '3', '4'],
      1,
      [
        'Ambos ceros también cuentan.',
        'Acepta los dos ceros y el 2.',
        '−4 queda fuera.',
      ],
    ),
    Question(
      'Un total empieza en 0 y suma solo los importes positivos de [2, −8, 5]. ¿Cuánto vale?',
      ['7', '2', '−1'],
      0,
      [
        '2 + 5 = 7.',
        'Dos es la cantidad de importes aceptados.',
        '−8 se descarta.',
      ],
    ),
    Question(
      '¿Cuál es el primer índice de un negativo en [3, 0, −5, −8], si se empieza a numerar por 0?',
      ['3', '−5', '2'],
      2,
      [
        'El índice 3 viene después de −5.',
        '−5 es el valor.',
        'La primera coincidencia está en el índice 2.',
      ],
    ),
  ],
  'rc': [
    Question(
      'Equipo 192.0.2.8/24, puerta 192.0.2.1. ¿Primer salto hacia 203.0.113.10 sin rutas especiales?',
      ['192.0.2.1', '203.0.113.10', '192.0.2.8'],
      0,
      [
        'El destino está fuera de la red local.',
        'Es el destino final.',
        'Es el propio emisor.',
      ],
    ),
    Question(
      '¿Dónde empieza el bloque de la dirección 192.0.2.200/26?',
      ['192.0.2.128', '192.0.2.192', '192.0.2.200'],
      1,
      [
        'El bloque .128 termina en .191.',
        '200 pertenece al intervalo 192–255.',
        '.200 es la dirección del equipo.',
      ],
    ),
    Question(
      'Una conexión TCP sin NAT va del puerto 53001 del cliente al 8443 del servidor. ¿A qué puerto llega la respuesta?',
      ['80', '8443', '53001'],
      2,
      [
        'Ese puerto no participa.',
        'En la respuesta es el origen.',
        'La respuesta tiene como destino el puerto del cliente.',
      ],
    ),
  ],
  'ac': [
    Question(
      'Caché vacía de una línea. Tras leer X, Y, Y, X, ¿cuántas lecturas aciertan?',
      ['2', '1', '0'],
      1,
      [
        'La última X ya había sido reemplazada.',
        'Solo la segunda lectura de Y acierta.',
        'La segunda Y aún está en la línea.',
      ],
    ),
    Question(
      'Con bloques de 8 bytes desde la dirección 0, ¿en qué bloque cae el byte 19?',
      ['2', '3', '19'],
      0,
      [
        'El bloque 2 contiene los bytes 16–23.',
        '3 es el desplazamiento dentro del bloque.',
        '19 es la dirección del byte.',
      ],
    ),
    Question(
      'Caché directa de cuatro líneas, inicialmente vacía. ¿Qué ocurre al leer los bloques 3, 7, 3?',
      ['Fallo, fallo, acierto', 'Fallo, acierto, fallo', 'Tres fallos'],
      2,
      [
        'El 7 reemplaza al primer 3.',
        'Acceder a la misma línea no implica que esté el mismo bloque.',
        'Ambos bloques compiten por la línea 3.',
      ],
    ),
  ],
};

int placementIndex(String subject, List<int?> answers) {
  final probes = diagnosticProbes[subject]!;
  if (answers.length != probes.length) {
    throw ArgumentError('Diagnóstico incompleto');
  }
  for (final (i, q) in probes.indexed) {
    if (answers[i] != q.answer) return i;
  }
  return probes.length;
}

Lesson nextLesson(
  List<Lesson> route,
  String? start,
  Set<String> completed,
  Set<String> drafts,
) {
  for (final lesson in route) {
    if (drafts.contains(lesson.id)) return lesson;
  }
  final index = route.indexWhere((l) => l.id == start);
  final ordered = index < 0
      ? route
      : [...route.skip(index), ...route.take(index)];
  return ordered.firstWhere(
    (l) => !completed.contains(l.id),
    orElse: () => ordered.first,
  );
}
