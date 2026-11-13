import 'dart:convert';
import 'dart:io';

import 'package:trama/catalog_source.dart';
import 'package:trama/diagnostic.dart';
import 'package:trama/review.dart';

String esc(String s) => const HtmlEscape().convert(s);
String question(Question q) {
  if (q.choices.isEmpty) {
    return '<p class="prompt">${esc(q.prompt)}</p><p><b>Clave:</b> &gt;= · Prueba con [], [0], [−1,2,4] y [−2,0,3].</p>';
  }
  return '<p class="prompt">${esc(q.prompt)}</p><ul>${q.choices.asMap().entries.map((e) => "<li>${e.key == q.answer ? '<strong>Correcta · ' : ''}${esc(e.value)}${e.key == q.answer ? '</strong>' : ''} — ${esc(q.feedback[e.key])}</li>").join()}</ul>';
}

void main() {
  const sources = {
    'fp': '<a href="https://docs.python.org/es/3/tutorial/controlflow.html">Documentación de Python · Control de flujo</a>',
    'rc': '<a href="https://www.rfc-editor.org/info/rfc4632/">CIDR</a> · <a href="https://datatracker.ietf.org/doc/html/rfc9293">TCP</a> · <a href="https://datatracker.ietf.org/doc/html/rfc1812#section-5.3.1">TTL en routers IPv4</a>',
    'ac': '<a href="https://www.cs.cornell.edu/courses/cs3410/2025sp/notes/caches.html">Cornell CS 3410 · Caches</a>',
  };
  final out = StringBuffer('''<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Trama · Revisión docente</title>
<style>body{margin:0;background:#f8f8f2;color:#18342f;font:17px/1.6 system-ui}header,main{padding:1.5rem max(5vw,calc((100vw - 960px)/2))}header{background:#07463e;color:white}main{max-width:100%}a{color:#006356}h1,h2,h3{line-height:1.25}h1{font:3rem Georgia,serif}h2{border-top:2px solid #176354;padding-top:1rem}article{background:white;border:1px solid #cedbd1;padding:1.2rem;margin:1rem 0;border-radius:12px}.prompt{white-space:pre-wrap;font-weight:600}summary{cursor:pointer;padding:.5rem 0}small{color:#436056}@media print{details> *{display:block}article{break-before:auto}h3,p.prompt{break-after:avoid}}</style>
<header><p>TRAMA / CUADERNO DE REVISIÓN</p><h1>Doce lecciones para el piloto</h1><p>Estado editorial · Pendiente de revisión docente externa</p></header><main><p><a href="diseno.html">Volver al diseño y al calendario</a> · <a href="./">Abrir la aplicación</a></p>
<p>Esta ficha se genera a partir de los mismos enunciados, soluciones y explicaciones que usa la aplicación. Las rutas son una propuesta independiente. Los títulos de las tres materias proceden del <a href="https://www.informatica.us.es/index.php/grados/ingenieria-del-software/plan-de-estudios">plan de la ETSII de Sevilla</a>. Los ejemplos y preguntas son originales de Trama; las referencias sirven para contrastar los conceptos. No se reproducen apuntes ni exámenes universitarios. La licencia de publicación del material original queda pendiente de decisión del titular.</p>
<h2>Cómo revisar</h2><p>Un revisor de la materia comprueba precisión, supuestos y soluciones. Un segundo revisor valora si la explicación prepara para resolver la tarea y si los errores reciben feedback comprensible. Revisar especialmente el límite de inclusión del cero, la diferencia entre puerto y dirección, y la penalización adicional en memoria.</p><p>Para cada observación registrar: código de lección o diagnóstico, número de ejercicio, problema, cambio propuesto, persona revisora, fecha y decisión (aceptar, corregir o retirar). Antes del piloto, comprobar la corrección en la versión web. Ninguna ficha figura como aprobada.</p>
<nav>''');
  for (final entry in entryLessons) {
    out.write('<a href="#${entry.id}">${entry.subject}</a> · ');
  }
  out.write('</nav>');
  for (final entry in entryLessons) {
    out.write(
      '<h2 id="${entry.id}">${entry.subject}</h2><p>Contraste técnico · ${sources[entry.id]}</p>',
    );
    for (final (i, l) in subjectRoute(entry.id).indexed) {
      out.write(
        '<article><small>${l.id} · LECCIÓN ${i + 1} / 4</small><h3>${esc(l.title)}</h3><p><strong>Objetivo.</strong> ${esc(l.goal)}</p><p>${esc(l.example)}</p><details><summary>Ver ejercicios, claves y feedback</summary>',
      );
      for (final q in l.questions) {
        out.write(question(q));
      }
      out.write(
        '</details><details><summary>Variante del primer repaso</summary>${question(reviewQuestion(l.id, 0))}</details></article>',
      );
    }
    out.write(
      '<details><summary>Diagnóstico inicial de la materia</summary><p>Las tres preguntas exploran, en orden, las tres primeras lecciones. Se recomienda la primera que requiera práctica o la cuarta si se aciertan todas. El alumno puede elegir otra lección.</p>',
    );
    for (final q in diagnosticProbes[entry.id]!) {
      out.write(question(q));
    }
    out.write('</details>');
  }
  File('docs/revision-docente.html')
      .writeAsStringSync('${out.toString()}</main></html>');
}
