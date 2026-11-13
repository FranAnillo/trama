import 'package:flutter/material.dart';

import 'data/journal.dart';
import 'diagnostic.dart';
import 'lessons.dart';

class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage(this.entry, this.journal, {super.key});
  final Lesson entry;
  final Journal journal;
  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  final answers = <int?>[];
  int? choice;
  bool saving = false;
  Lesson? recommendation;
  String? error;
  late final probes = diagnosticProbes[widget.entry.subjectId]!;

  Future<void> confirm() async {
    if (saving || choice == null) return;
    final answer = choice == -1 ? null : choice;
    if (answers.length + 1 < probes.length) {
      setState(() {
        answers.add(answer);
        choice = null;
      });
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final lesson = await widget.journal.savePlacement(
        widget.entry.subjectId,
        [...answers, answer],
      );
      if (mounted) {
        setState(() {
          answers.add(answer);
          recommendation = lesson;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'No se pudo guardar la recomendación. Vuelve a intentarlo.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = recommendation;
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico inicial')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 710),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                widget.entry.subject,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (result == null) ...[
                const Text(
                  'Tres preguntas para elegir por dónde empezar. Puedes salir en cualquier momento. El diagnóstico no da XP.',
                ),
                const SizedBox(height: 16),
                Text('Pregunta ${answers.length + 1} de ${probes.length}'),
                const SizedBox(height: 8),
                Text(
                  probes[answers.length].prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final (i, label) in [
                  ...probes[answers.length].choices,
                  'Todavía no lo sé',
                ].indexed)
                  Builder(
                    builder: (context) {
                      final option = i == probes[answers.length].choices.length
                          ? -1
                          : i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Semantics(
                          selected: choice == option,
                          child: OutlinedButton(
                            onPressed: saving
                                ? null
                                : () => setState(() => choice = option),
                            child: Text(
                              '${choice == option ? "●  " : ""}$label',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (error != null) Text(error!),
                FilledButton(
                  onPressed: saving || choice == null ? null : confirm,
                  child: Text(
                    answers.length + 1 == probes.length
                        ? 'Ver recomendación'
                        : 'Siguiente pregunta',
                  ),
                ),
              ] else ...[
                Text(
                  'Te recomendamos «${result.title}»',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  result == subjectRoute(widget.entry.subjectId).last
                      ? 'Has resuelto las tres preguntas. Puedes pasar a la cuarta lección.'
                      : 'Esta lección trabaja el primer concepto que conviene reforzar.',
                ),
                const SizedBox(height: 16),
                for (final (i, probe) in probes.indexed)
                  ListTile(
                    title: Text(subjectRoute(widget.entry.subjectId)[i].title),
                    subtitle: Text(
                      '${answers[i] == probe.answer
                          ? "Correcto"
                          : answers[i] == null
                          ? "Pendiente de practicar"
                          : "Para revisar"} · ${probe.feedback[answers[i] ?? probe.answer]}',
                    ),
                  ),
                const Text(
                  'Tu ruta sigue abierta. Puedes elegir cualquiera de sus cuatro lecciones.',
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, result),
                  child: const Text('Abrir lección recomendada'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver al cuaderno'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
