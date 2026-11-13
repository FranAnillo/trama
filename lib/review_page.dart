import 'package:flutter/material.dart';

import 'data/journal.dart';
import 'lessons.dart';
import 'review.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage(
    this.lesson,
    this.plan,
    this.journal, {
    super.key,
    required this.preview,
  });
  final Lesson lesson;
  final ReviewPlan plan;
  final Journal journal;
  final bool preview;
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final q = reviewQuestion(
    widget.lesson.id,
    widget.plan.round,
    preview: widget.preview,
  );
  int? choice;
  Check? result;
  bool busy = false;
  String? error;

  Future<void> confirm() async {
    if (busy || choice == null || result != null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!widget.preview) {
        await widget.journal.recordReview(
          widget.lesson.id,
          widget.plan.round,
          '$choice',
        );
      }
      if (mounted) setState(() => result = grade(q, '$choice'));
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StateError
              ? 'La programación ha cambiado. Vuelve al cuaderno para ver el repaso vigente.'
              : 'No se pudo guardar. Puedes volver a intentarlo.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.preview ? 'Ensayar una variante' : 'Repasar hoy'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 710),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              widget.lesson.subject,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.preview
                  ? 'Ensayo libre. Tu próximo repaso mantiene su fecha y esta respuesta queda fuera del historial de recuerdo.'
                  : 'Intenta resolver esta variante sin pistas. La primera respuesta cuenta para tu historial de recuerdo.',
            ),
            const SizedBox(height: 24),
            Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final (index, label) in q.choices.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  selected: index == choice,
                  child: OutlinedButton(
                    onPressed: busy || result != null
                        ? null
                        : () => setState(() => choice = index),
                    child: Text('${index == choice ? "●  " : ""}$label'),
                  ),
                ),
              ),
            if (error != null) Text(error!),
            if (result == null)
              FilledButton(
                onPressed: choice == null || busy ? null : confirm,
                child: const Text('Comprobar'),
              )
            else ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  '${result!.correct ? "Correcto" : "Para revisar"} · ${result!.feedback}',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
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
