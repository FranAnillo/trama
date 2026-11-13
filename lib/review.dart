import 'lessons.dart';

typedef JournalRow = Map<String, Object?>;

/// One retrieval task per concept, with practice examples kept separate.
Question reviewQuestion(String lesson, int round, {bool preview = false}) {
  final seed = round * 2 + (preview ? 1 : 0);
  late List<String> choices;
  late String prompt, solution, reason;
  switch (lesson) {
    case 'ac':
      final blocks = ['A', 'B', 'C'];
      final start = seed % 3;
      final a = blocks[start], b = blocks[(start + 1) % 3];
      final trace = switch (seed % 5) {
        0 => [b, a, a, b, b],
        1 => [a, b, b, b, a],
        2 => [b, a, b, a, b],
        3 => [a, a, b, a, a, a],
        _ => [a, b, b, a, a],
      };
      final hits = [
        for (var i = 1; i < trace.length; i++)
          if (trace[i] == trace[i - 1]) trace[i],
      ];
      prompt =
          'Caché vacía de una línea. Lee ${trace.join(" → ")}. ¿Cuántas lecturas aciertan?';
      solution = '${hits.length}';
      reason =
          'Una lectura acierta cuando repite el bloque de la lectura anterior. En esta traza hay $solution.';
      choices = ['0', '1', '2', '3'];
    case 'rc':
      final host = 10 + seed % 170;
      final local = (round + (preview ? 1 : 0)).isOdd;
      final target = local ? '10.$host.2.80' : '10.$host.3.80';
      prompt =
          'Tu equipo es 10.$host.2.20/24 y su puerta es 10.$host.2.1. En una LAN sin rutas especiales, ¿a qué equipo entrega la trama para llegar a $target?';
      solution = local ? target : '10.$host.2.1';
      reason = local
          ? 'Los tres primeros octetos coinciden. La entrega es directa a $target.'
          : 'El tercer octeto cambia. La trama sale por 10.$host.2.1 y el paquete conserva $target como IP final.';
      choices = [target, '10.$host.2.1', '10.$host.2.20'];
    case 'fp':
      final inclusive = (round + (preview ? 1 : 0)).isEven;
      final values = [
        -(seed + 2),
        0,
        seed + 3,
        if (seed % 3 != 0) 0,
        if (seed % 3 == 1) seed + 5,
      ];
      final accepted = values.where((v) => inclusive ? v >= 0 : v > 0).toList();
      prompt =
          'El contador empieza en 0. Suma uno por cada x que cumple x ${inclusive ? ">=" : ">"} 0. ¿Qué devuelve para $values?';
      solution = '${accepted.length}';
      reason =
          'Pasan la condición $accepted. El cero ${inclusive ? "sí" : "no"} cuenta con este operador.';
      choices = ['0', '1', '2', '3', '4'];
    case 'fp.sum':
      final a = seed + 3, b = seed + 5;
      prompt =
          '¿Qué suma obtiene un acumulador que empieza en 0 y añade solo los positivos de [$a, −2, $b]?';
      solution = '${a + b}';
      reason = 'Suma $a + $b. Se descarta −2.';
      choices = [solution, '${a + b - 2}', '2'];
    case 'fp.find':
      final limit = 10 + seed, index = seed % 3;
      final values = [
        for (var i = 0; i < index; i++) limit - i,
        limit + 1,
        limit + 4,
      ];
      prompt =
          'Índices desde 0. En $values, ¿qué índice es el primero con valor mayor que $limit?';
      solution = '$index';
      reason =
          'Los anteriores no superan $limit. ${values[index]} sí, en la posición $index.';
      choices = ['0', '1', '2', '−1'];
    case 'fp.func':
      final x = seed + 4;
      prompt = 'def triple(n): return 3*n. ¿Cuánto vale triple($x) + 2?';
      solution = '${3 * x + 2}';
      reason = 'Se devuelve ${3 * x} y después se suman 2.';
      choices = [solution, '${3 * x}', '${3 * (x + 2)}'];
    case 'rc.prefix':
      final base = (seed % 4) * 64;
      final ip = base + 1 + seed % 60;
      final part = seed % 250;
      prompt = '¿En qué dirección empieza la red del equipo 10.0.$part.$ip/26?';
      solution = '10.0.$part.$base';
      reason = 'El último octeto $ip está entre $base y ${base + 63}.';
      choices = [solution, '10.0.$part.$ip', '10.0.$part.${base + 63}'];
    case 'rc.port':
      final client = 50000 + seed % 10000, server = 8000 + seed % 1000;
      final destination = (round + (preview ? 1 : 0)).isEven;
      prompt =
          'TCP sin traducción de puertos. Cliente $client → servidor $server. En la respuesta, ¿cuál es el puerto de ${destination ? "destino" : "origen"}?';
      solution = '${destination ? client : server}';
      reason = 'El servidor responde desde $server hacia $client.';
      choices = ['$client', '$server', '443'];
    case 'rc.ttl':
      final routers = 2 + seed % 7;
      final ttl = routers + 2 + seed % 3;
      prompt =
          'Un paquete IPv4 sale con TTL $ttl. Pasa por $routers routers, cada uno resta uno. ¿Con qué TTL llega al destino?';
      solution = '${ttl - routers}';
      reason =
          '$ttl − $routers = $solution. El destino no realiza otro reenvío.';
      choices = [solution, '${ttl - routers - 1}', '$ttl'];
    case 'ac.block':
      final size = (round + (preview ? 1 : 0)).isEven ? 4 : 8;
      final block = seed + 2,
          offset = 1 + seed % (size - 1),
          addr = block * size + offset;
      prompt =
          'Con bloques de $size bytes y numeración desde 0, ¿cuál es el desplazamiento del byte $addr en su bloque?';
      solution = '$offset';
      reason =
          'El bloque empieza en ${block * size}. La diferencia es $offset.';
      choices = [solution, '${offset - 1}', '$size'];
    case 'ac.line':
      final lines = (round + (preview ? 1 : 0)).isEven ? 4 : 8;
      final block = 9 + seed;
      prompt =
          'Correspondencia directa con $lines líneas desde 0. ¿En qué línea se aloja el bloque $block?';
      solution = '${block % lines}';
      reason = 'El índice es $block módulo $lines, es decir, $solution.';
      choices = [solution, '${(block + 1) % lines}', '${(block + 2) % lines}'];
    case 'ac.time':
      final hit = 2 + seed, penalty = 20 + 10 * seed;
      prompt =
          'La consulta cuesta $hit ns, el 10 % de los accesos falla y un fallo cuesta $penalty ns adicionales. ¿Cuál es el tiempo medio?';
      solution = '${hit + penalty ~/ 10} ns';
      reason = '$hit + 0,10 × $penalty = $solution.';
      choices = [solution, '${hit + penalty} ns', '$hit ns'];
    default:
      throw ArgumentError.value(lesson);
  }
  final shift = (round + (preview ? 2 : 1)) % choices.length;
  choices = [...choices.skip(shift), ...choices.take(shift)];
  return Question(prompt, choices, choices.indexOf(solution), [
    for (final s in choices)
      s == solution ? reason : 'La respuesta es $solution. $reason',
  ]);
}

/// The first completion starts the calendar. Repeating the base lesson does
/// not postpone a due review. Only scheduled, unaided retrieval is evidence.
class ReviewPlan {
  ReviewPlan(this.lesson, this.due, this.round, this.streak, this.lastCorrect);
  final String lesson;
  final DateTime due;
  final int round, streak;
  final bool? lastCorrect;
  bool ready(DateTime now) => !now.isBefore(due);

  static ReviewPlan? fromHistory(
    String lesson,
    List<JournalRow> sessions,
    List<JournalRow> reviews,
  ) {
    final times =
        sessions
            .where((e) => e['lesson'] == lesson)
            .map((e) => DateTime.parse(e['time'] as String))
            .toList()
          ..sort();
    if (times.isEmpty) return null;
    final attempts = reviews.where((e) => e['lesson'] == lesson).toList()
      ..sort((a, b) {
        final order = DateTime.parse(a['time'] as String)
            .compareTo(DateTime.parse(b['time'] as String));
        if (order != 0) return order;
        final roundOrder = (a['round'] as int).compareTo(b['round'] as int);
        if (roundOrder != 0) return roundOrder;
        return (a['answer'] as String).compareTo(b['answer'] as String);
      });
    var anchor = times.first;
    var streak = 0;
    bool? lastCorrect;
    var round = 0;
    const gaps = [1, 3, 7, 14];
    for (final row in attempts) {
      final attemptRound = row['round'] as int;
      if (attemptRound >= round) round = attemptRound + 1;
      final time = DateTime.parse(row['time'] as String);
      if (time.isBefore(anchor.add(Duration(days: gaps[streak.clamp(0, 3)])))) {
        continue;
      }
      anchor = time;
      lastCorrect = row['correct'] == true;
      streak = lastCorrect ? streak + 1 : 0;
    }
    return ReviewPlan(
      lesson,
      anchor.add(Duration(days: gaps[streak.clamp(0, 3)])),
      round,
      streak,
      lastCorrect,
    );
  }
}
