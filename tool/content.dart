import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:trama/catalog_source.dart';

String literal(String s) => jsonEncode(s).replaceAll(r'$', r'\$');

Map<String, Object?> encodeLesson(Lesson l) => {
  'id': l.id,
  'version': 1,
  'subject': l.subject,
  'title': l.title,
  'goal': l.goal,
  'example': l.example,
  'questions': [
    for (final q in l.questions)
      {
        'prompt': q.prompt,
        'choices': q.choices,
        'answer': q.answer,
        'feedback': q.feedback,
      },
  ],
};

void main() {
  Directory('content').createSync();
  final catalog = StringBuffer(
    "import 'lesson_model.dart';\nexport 'lesson_model.dart';\n\n",
  );
  final manifests = StringBuffer(
    "const contentManifest = <String,({int bytes,String hash})>{\n",
  );
  // Three entry lessons remain available in the application from first launch.
  for (final (name, list) in [
    ('entryLessons', entryLessons),
    ('additionalLessons', additionalLessons),
  ]) {
    catalog.writeln('const $name = [');
    for (final l in list) {
      final data = utf8.encode(jsonEncode(encodeLesson(l)));
      File('content/${l.id}.v1.json').writeAsBytesSync(data);
      manifests.writeln(
        '${literal(l.id)}: (bytes:${data.length},hash:"${sha256.convert(data)}"),',
      );
      catalog.write(
        'Lesson(${[l.id, l.subject, l.title, l.goal, name == "entryLessons" ? l.example : ""].map(literal).join(",")}, [',
      );
      if (name == 'entryLessons') {
        for (final q in l.questions) {
          catalog.write(
            'Question(${literal(q.prompt)},${jsonEncode(q.choices)},${q.answer},${jsonEncode(q.feedback)}),',
          );
        }
      }
      catalog.writeln(']),');
    }
    catalog.writeln('];');
  }
  catalog.writeln('const lessons=[...entryLessons,...additionalLessons];');
  catalog.writeln(
    'List<Lesson> subjectRoute(String id)=>lessons.where((l)=>l.subjectId==id).toList();',
  );
  File('lib/lessons.dart').writeAsStringSync(catalog.toString());
  File('lib/content_manifest.dart').writeAsStringSync('$manifests};\n');
}
