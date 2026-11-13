import 'dart:convert';
import 'dart:io';

import 'package:trama/catalog_source.dart';
import 'package:trama/review.dart';

void main() {
  final rows = <Map<String, Object?>>[];
  for (final lesson in lessons) {
    rows.add({
      'key': 'session/${lesson.id}',
      'answers': [
        for (final q in lesson.questions)
          q.choices.isEmpty ? '>=' : '${q.answer}',
      ],
    });
    for (var round = 0; round < 128; round++) {
      rows.add({
        'key': 'review/${lesson.id}/$round',
        'answers': ['${reviewQuestion(lesson.id, round).answer}'],
      });
    }
  }
  final data = jsonEncode(rows);
  File('backend/rubrics.sql').writeAsStringSync(
    """-- Generated from the same version 1 content as the client.
insert into public.trama_rubrics(key,answers)
select key,answers from jsonb_to_recordset(\$rubrics\$$data\$rubrics\$::jsonb) as r(key text, answers jsonb)
on conflict(key) do update set answers=excluded.answers;
""",
  );
}
