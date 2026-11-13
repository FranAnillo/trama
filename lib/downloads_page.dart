import 'package:flutter/material.dart';

import 'data/content.dart';
import 'content_manifest.dart';
import 'lessons.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage(this.content, {super.key});
  final LessonStore content;
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  Set<String> installed = {};
  String? busy;
  String? error;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final values = await widget.content.installed();
      if (mounted) {
        setState(() {
          installed = values;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'No se pudo consultar el almacenamiento.';
          loading = false;
        });
      }
    }
  }

  Future<void> change(Lesson lesson) async {
    setState(() {
      busy = lesson.id;
      error = null;
    });
    try {
      if (installed.contains(lesson.id)) {
        await widget.content.remove(lesson.id);
      } else {
        await widget.content.download(lesson);
      }
      await refresh();
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'No se pudo completar la operación. Comprueba la conexión y el espacio disponible. Puedes reintentar.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Unidades sin conexión')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 710),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Las tres lecciones iniciales vienen incluidas. Guarda las demás para estudiarlas sin conexión. Quitar una unidad libera su contenido y conserva tus respuestas y repasos.',
            ),
            if (loading) const LinearProgressIndicator(),
            if (error != null) Text(error!),
            for (final entry in entryLessons) ...[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Text(
                  entry.subject,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final lesson in subjectRoute(entry.id))
                ListTile(
                  title: Text(lesson.title),
                  subtitle: Text(
                    lesson.questions.isNotEmpty
                        ? 'Incluida en la aplicación'
                        : '${installed.contains(lesson.id) ? "Guardada" : "Disponible para descargar"} · ${(contentManifest[lesson.id]!.bytes / 1024).toStringAsFixed(1)} KB · versión 1',
                  ),
                  trailing: lesson.questions.isNotEmpty
                      ? const Icon(Icons.check_circle_outline)
                      : busy == lesson.id
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : IconButton(
                          tooltip: installed.contains(lesson.id)
                              ? 'Quitar unidad'
                              : 'Descargar unidad',
                          onPressed: loading || busy != null
                              ? null
                              : () => change(lesson),
                          icon: Icon(
                            installed.contains(lesson.id)
                                ? Icons.delete_outline
                                : Icons.download_outlined,
                          ),
                        ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
