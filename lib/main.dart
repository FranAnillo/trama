import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/journal.dart';
import 'data/native.dart' if (dart.library.js_interop) 'data/browser.dart';
import 'lessons.dart';
import 'cache_lab.dart';
import 'diagnostic.dart';
import 'diagnostic_page.dart';
import 'review.dart';
import 'review_page.dart';
import 'downloads_page.dart';
import 'account_page.dart';
import 'content_manifest.dart';
import 'data/sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(Trama(Journal(await openLocal())));
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Text(
                'No se pudo abrir el cuaderno. Comprueba el espacio y los permisos de almacenamiento y vuelve a abrir Trama.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Trama extends StatelessWidget {
  const Trama(this.journal, {super.key});
  final Journal journal;

  @override
  Widget build(BuildContext context) {
    ThemeData palette(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff00675d),
        brightness: brightness,
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Trama',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es')],
      theme: palette(Brightness.light),
      darkTheme: palette(Brightness.dark),
      home: Desk(journal),
    );
  }
}

class Desk extends StatefulWidget {
  const Desk(this.journal, {super.key});
  final Journal journal;
  @override
  State<Desk> createState() => _DeskState();
}

class _DeskState extends State<Desk> {
  Set<String> selected = {};
  List<Map<String, Object?>> history = [];
  Map<String, JournalRow> drafts = {};
  List<JournalRow> reviews = [];
  Map<String, String> placements = {};
  Timer? dueTimer;
  String? problem;
  bool loading = true;
  int page = 0;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    try {
      final subjects = await widget.journal.selected();
      final records = await widget.journal.history();
      final partial = await widget.journal.unfinished();
      final starts = await widget.journal.placements();
      final retrievals = await widget.journal.reviewHistory();
      if (!mounted) return;
      setState(() {
        placements = starts;
        drafts = partial;
        reviews = retrievals;
        selected = subjects;
        history = records;
        loading = false;
        problem = null;
      });
      scheduleRefresh();
    } catch (_) {
      if (mounted) {
        setState(() {
          problem = 'No se pudo leer tu progreso.';
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    dueTimer?.cancel();
    super.dispose();
  }

  List<ReviewPlan> get plans => [
    for (final lesson in lessons)
      ?ReviewPlan.fromHistory(lesson.id, history, reviews),
  ];

  void scheduleRefresh() {
    dueTimer?.cancel();
    final now = widget.journal.now();
    final upcoming =
        plans.map((p) => p.due).where((time) => time.isAfter(now)).toList()
          ..sort();
    if (upcoming.isNotEmpty) {
      dueTimer = Timer(upcoming.first.difference(now), () {
        if (mounted) reload();
      });
    }
  }

  Future<void> review(
    Lesson lesson,
    ReviewPlan plan, {
    bool preview = false,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReviewPage(lesson, plan, widget.journal, preview: preview),
      ),
    );
    await reload();
  }

  String formatDue(BuildContext context, DateTime time) {
    final local = time.toLocal();
    final labels = MaterialLocalizations.of(context);
    return '${labels.formatShortDate(local)} · ${labels.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
  }

  Future<void> choose() async {
    final draft = {...selected};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, change) => AlertDialog(
          title: const Text('Mis materias'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final l in entryLessons)
                  CheckboxListTile(
                    value: draft.contains(l.id),
                    title: Text(l.subject),
                    onChanged: (value) => change(() {
                      if (value == true) {
                        draft.add(l.id);
                      } else {
                        draft.remove(l.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: draft.isEmpty ? null : () => Navigator.pop(ctx, draft),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    try {
      await widget.journal.select(result);
      if (mounted) setState(() => selected = result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la selección.')),
        );
      }
    }
  }

  Future<void> study(Lesson lesson) async {
    try {
      var content = lesson;
      if (lesson.questions.isEmpty) {
        final installed = await widget.journal.content.installed();
        if (!mounted) return;
        if (!installed.contains(lesson.id)) {
          final approved = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(lesson.title),
              content: Text(
                'Descarga de ${(contentManifest[lesson.id]!.bytes / 1024).toStringAsFixed(1)} KB · versión 1. Después podrás abrirla sin conexión.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Volver'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Descargar y abrir'),
                ),
              ],
            ),
          );
          if (approved != true || !mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Descargando unidad…')));
          content = await widget.journal.content.download(lesson);
          if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        } else {
          content = await widget.journal.content.open(lesson);
        }
      }
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => Study(content, widget.journal, drafts[lesson.id]),
        ),
      );
      await reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir la unidad. Comprueba la conexión o vuelve a descargarla desde Unidades sin conexión.',
            ),
          ),
        );
      }
    }
  }

  Future<void> account() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountPage(SyncEngine(widget.journal.db)),
      ),
    );
    await reload();
  }

  Future<void> downloads() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => DownloadsPage(widget.journal.content)),
    );
    await reload();
  }

  Future<void> diagnose(Lesson entry) async {
    final lesson = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(builder: (_) => DiagnosticPage(entry, widget.journal)),
    );
    if (!mounted) return;
    await reload();
    if (lesson != null && mounted) await study(lesson);
  }

  Future<void> chooseLesson(List<Lesson> route, Set<String> completed) async {
    final chosen = await showDialog<Lesson>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(route.first.subject),
        children: [
          for (final (i, l) in route.indexed)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${i + 1}. ${l.title}'),
                subtitle: Text(l.goal),
                trailing: drafts.containsKey(l.id)
                    ? const Icon(Icons.pause_circle_outline)
                    : completed.contains(l.id)
                    ? const Icon(Icons.check_circle_outline)
                    : null,
              ),
            ),
        ],
      ),
    );
    if (chosen != null && mounted) await study(chosen);
  }

  Widget routeCard(Lesson entry, Set<String> completed) {
    final route = subjectRoute(entry.id);
    final lesson = nextLesson(
      route,
      placements[entry.id],
      completed,
      drafts.keys.toSet(),
    );
    final done = route.where((l) => completed.contains(l.id)).length;
    final recommended = placements[entry.id];
    final start = route.where((l) => l.id == recommended).firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.subject, style: Theme.of(context).textTheme.titleLarge),
            Text('$done de ${route.length} lecciones completadas'),
            const SizedBox(height: 10),
            if (start != null)
              Text('Tu diagnóstico sugiere empezar por «${start.title}».'),
            Text(lesson.title, style: Theme.of(context).textTheme.titleMedium),
            Text(lesson.goal),
            if (drafts[lesson.id] case final draft?)
              Text(
                '${(draft['answers'] as List).length} de 3 respuestas guardadas',
              ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () => study(lesson),
              child: Text(
                drafts.containsKey(lesson.id)
                    ? 'Continuar donde lo dejaste'
                    : completed.contains(lesson.id)
                    ? 'Practicar de nuevo'
                    : 'Abrir lección',
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => chooseLesson(route, completed),
                  child: const Text('Ver las 4 lecciones'),
                ),
                TextButton(
                  onPressed: () => diagnose(entry),
                  child: Text(
                    start == null
                        ? 'Diagnóstico opcional'
                        : 'Repetir diagnóstico',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = history.map((e) => e['lesson'] as String).toSet();
    final selectedPlans =
        plans
            .where(
              (p) => selected.contains(
                lessons.firstWhere((l) => l.id == p.lesson).subjectId,
              ),
            )
            .toList()
          ..sort((a, b) => a.due.compareTo(b.due));
    final pending = selectedPlans
        .where((p) => p.ready(widget.journal.now()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trama'),
        actions: [
          IconButton(
            onPressed: account,
            tooltip: 'Cuenta y sincronización',
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            onPressed: downloads,
            tooltip: 'Unidades sin conexión',
            icon: const Icon(Icons.download_outlined),
          ),
          TextButton.icon(
            onPressed: loading ? null : choose,
            icon: const Icon(Icons.tune),
            label: const Text('Materias'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (i) => setState(() => page = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Aprender',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Mi progreso',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 710),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 48),
            children: [
              Text(
                'CUADERNO DE INFORMÁTICA   /   01',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                page == 0 ? 'Tu mesa de estudio' : 'Mi progreso',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                page == 0
                    ? 'Elige lo que quieres entender hoy. Cada práctica cabe en unos minutos.'
                    : 'Los XP reconocen la práctica. Tus aciertos muestran qué conviene volver a trabajar.',
              ),
              const SizedBox(height: 24),
              if (loading)
                const LinearProgressIndicator()
              else if (problem != null) ...[
                Text(problem!),
                TextButton(onPressed: reload, child: const Text('Reintentar')),
              ] else if (page == 0) ...[
                if (selected.isEmpty)
                  Card(
                    color: cs.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.hub_outlined, size: 32),
                          const SizedBox(height: 16),
                          Text(
                            'Tres formas de empezar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Escribe una condición, sigue un paquete de red o experimenta con una caché. Puedes elegir una materia y añadir otra más adelante.',
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: choose,
                            child: const Text('Elegir mis materias'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (selectedPlans.isNotEmpty)
                  Card(
                    color: cs.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repasar hoy',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (pending.isEmpty)
                            Text(
                              'Al día. Próximo repaso: ${formatDue(context, selectedPlans.first.due)}.',
                            ),
                          for (final plan in pending)
                            ListTile(
                              title: Text(
                                lessons
                                    .firstWhere((l) => l.id == plan.lesson)
                                    .title,
                              ),
                              subtitle: const Text('Variante pendiente'),
                              trailing: const Icon(Icons.arrow_forward),
                              onTap: () => review(
                                lessons.firstWhere((l) => l.id == plan.lesson),
                                plan,
                              ),
                            ),
                          for (final plan in selectedPlans)
                            TextButton(
                              onPressed: () => review(
                                lessons.firstWhere((l) => l.id == plan.lesson),
                                plan,
                                preview: true,
                              ),
                              child: Text(
                                selectedPlans.length == 1
                                    ? 'Ensayar una variante'
                                    : 'Ensayar · ${lessons.firstWhere((l) => l.id == plan.lesson).title}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                for (final entry in entryLessons.where(
                  (l) => selected.contains(l.id),
                ))
                  routeCard(entry, completed),
              ] else ...[
                Text(
                  '${completed.length * 10} XP · ${history.length} sesiones terminadas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final l in lessons.where((l) => completed.contains(l.id)))
                  Builder(
                    builder: (context) {
                      final sessions =
                          history.where((s) => s['lesson'] == l.id).toList()
                            ..sort(
                              (a, b) => (b['time'] as String).compareTo(
                                a['time'] as String,
                              ),
                            );
                      final latest = sessions.first;
                      final answers = latest['answers'] as List;
                      final hits = answers
                          .where((e) => e['correct'] == true)
                          .length;
                      final plan = ReviewPlan.fromHistory(
                        l.id,
                        history,
                        reviews,
                      )!;
                      final memory = switch (plan.lastCorrect) {
                        null => 'Aún sin comprobar',
                        true => 'Recordado en el último repaso',
                        false => 'Necesita repaso',
                      };
                      return ListTile(
                        title: Text('${l.subject} · ${l.title}'),
                        subtitle: Text(
                          'Práctica · $hits/${answers.length} en la última sesión\nRecuerdo · $memory (${plan.round} ${plan.round == 1 ? "repaso" : "repasos"})\nPróximo repaso · ${formatDue(context, plan.due)}',
                        ),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => study(l),
                      );
                    },
                  ),
                if (completed.isEmpty)
                  const Text(
                    'Al terminar tu primera lección aparecerán aquí sus resultados.',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class Study extends StatefulWidget {
  const Study(this.lesson, this.journal, this.draft, {super.key});
  final JournalRow? draft;
  final Lesson lesson;
  final Journal journal;
  @override
  State<Study> createState() => _StudyState();
}

class _StudyState extends State<Study> {
  late final String session =
      widget.draft?['id'] as String? ??
      List.generate(
        16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
  late int step = widget.draft == null ? -1 : evidence.length;
  String? value;
  Check? check;
  bool saving = false;
  late List<JournalRow> evidence = List<JournalRow>.from(
    widget.draft?['answers'] as List? ?? [],
  );
  final editor = TextEditingController();

  @override
  void dispose() {
    editor.dispose();
    super.dispose();
  }

  void advance() {
    setState(() {
      step++;
      check = null;
      value = null;
      editor.clear();
    });
  }

  Future<void> submit(Question q) async {
    if (saving || check != null || value == null) return;
    final input = value!;
    setState(() => saving = true);
    try {
      final rows = await widget.journal.confirm(
        session,
        widget.lesson,
        step,
        input,
      );
      if (mounted) {
        setState(() {
          evidence = rows;
          check = grade(q, input);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? 'La sesión cambió en otra ventana. Vuelve al cuaderno para continuar.'
                  : 'No se guardó la respuesta. Pulsa Comprobar para reintentar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final done = step == l.questions.length;
    final q = step >= 0 && !done ? l.questions[step] : null;
    return Scaffold(
      appBar: AppBar(title: Text(l.subject)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 710),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                done
                    ? 'RESULTADOS'
                    : step < 0
                    ? 'PUNTO DE PARTIDA'
                    : 'PRÁCTICA · ${step + 1} DE ${l.questions.length}',
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value:
                    (step + 1).clamp(0, l.questions.length) /
                    l.questions.length,
              ),
              const SizedBox(height: 22),
              Text(l.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              if (step < 0) ...[
                Text(l.goal, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(l.example),
                const Text(
                  'Puedes salir después de comprobar una respuesta y continuar aquí más tarde.',
                ),
                if (l.id == 'ac') const CacheLab(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: advance,
                  child: const Text('Empezar práctica'),
                ),
              ] else if (done) ...[
                Text(
                  '${evidence.where((e) => e['correct'] == true).length} de ${evidence.length} respuestas correctas.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sesión guardada en este dispositivo. Vuelve mañana para comprobar qué recuerdas.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver al cuaderno'),
                ),
              ] else if (q != null) ...[
                SelectableText(
                  q.prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (q.choices.isEmpty)
                  TextField(
                    controller: editor,
                    enabled: check == null && !saving,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Operador de Python',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (s) => setState(() => value = s),
                  )
                else
                  for (final (i, choice) in q.choices.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        selected: value == '$i',
                        child: OutlinedButton(
                          onPressed: saving || check != null
                              ? null
                              : () => setState(() => value = '$i'),
                          child: Text('${value == '$i' ? '●  ' : ''}$choice'),
                        ),
                      ),
                    ),
                if (check == null)
                  FilledButton(
                    onPressed: saving || value == null || value!.trim().isEmpty
                        ? null
                        : () => submit(q),
                    child: const Text('Comprobar'),
                  )
                else ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '${check!.correct ? "Correcto" : "Para revisar"} · ${check!.feedback}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: saving ? null : advance,
                    child: Text(
                      step == l.questions.length - 1
                          ? 'Ver resultados'
                          : 'Continuar',
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
