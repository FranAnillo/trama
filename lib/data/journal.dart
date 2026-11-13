import 'package:sembast/sembast.dart';

import '../lessons.dart';
import 'content.dart';
import '../diagnostic.dart';
import '../review.dart';

class Journal {
  Journal(this.db, {DateTime Function()? clock, ContentFetch? fetch})
    : now = clock ?? DateTime.now,
      content = LessonStore(db, fetch: fetch);
  final LessonStore content;
  final DateTime Function() now;
  final Database db;
  final entries = stringMapStoreFactory.store('sessions');
  final drafts = stringMapStoreFactory.store('study_drafts_v1');
  final reviews = stringMapStoreFactory.store('review_attempts_v1');
  final diagnostics = stringMapStoreFactory.store('placement_v1');
  final config = stringMapStoreFactory.store('config');

  Future<Map<String, String>> placements() async => {
    for (final row in await diagnostics.find(db))
      row.key: row.value['recommended'] as String,
  };

  Future<Lesson> savePlacement(String subject, List<int?> answers) async {
    final index = placementIndex(subject, answers);
    final lesson = subjectRoute(subject)[index];
    await diagnostics.record(subject).put(db, {
      'version': 1,
      'recommended': lesson.id,
      'answers': answers,
      'time': now().toUtc().toIso8601String(),
    });
    return lesson;
  }

  Future<Set<String>> selected() async {
    final prefs = await config.record('subjects').get(db);
    return ((prefs?['ids'] as List?) ?? []).cast<String>().toSet();
  }

  Future<void> select(Set<String> ids) async {
    await config.record('subjects').put(db, {'ids': ids.toList()});
  }

  Future<List<Map<String, Object?>>> history() async =>
      (await entries.find(db)).map((r) => r.value).toList();

  Future<Map<String, JournalRow>> unfinished() async => {
    for (final r in await drafts.find(db)) r.key: r.value,
  };

  Future<List<JournalRow>> reviewHistory() async =>
      (await reviews.find(db)).map((r) => r.value).toList();

  // Check the expected position in the same transaction as the write. An old
  // tab can neither overwrite a confirmed answer nor resurrect a finished run.
  Future<List<JournalRow>> confirm(
    String id,
    Lesson lesson,
    int step,
    String answer,
  ) => db.transaction((txn) async {
    final ref = drafts.record(lesson.id);
    final draft = await ref.get(txn);
    if (await entries.record(id).exists(txn) ||
        (draft != null && draft['id'] != id)) {
      throw StateError('session changed');
    }
    final evidence = List<JournalRow>.from(draft?['answers'] as List? ?? []);
    if (step != evidence.length) throw StateError('position changed');
    evidence.add({
      'item': step,
      'answer': answer,
      'correct': grade(lesson.questions[step], answer).correct,
    });
    if (evidence.length == lesson.questions.length) {
      await entries.record(id).put(txn, {
        'lesson': lesson.id,
        'version': 1,
        'time': now().toUtc().toIso8601String(),
        'answers': evidence,
      });
      await ref.delete(txn);
    } else {
      await ref.put(txn, {'id': id, 'version': 1, 'answers': evidence});
    }
    return evidence;
  });

  Future<void> recordReview(String lesson, int round, String answer) =>
      db.transaction((txn) async {
        final sessions = (await entries.find(txn)).map((e) => e.value).toList();
        final past = (await reviews.find(txn)).map((e) => e.value).toList();
        final plan = ReviewPlan.fromHistory(lesson, sessions, past);
        final time = now().toUtc();
        if (plan == null || plan.round != round || !plan.ready(time)) {
          throw StateError('review is not due');
        }
        final question = reviewQuestion(lesson, round);
        await reviews.record('$lesson/$round').put(txn, {
          'lesson': lesson,
          'round': round,
          'version': 1,
          'answer': answer,
          'correct': grade(question, answer).correct,
          'time': time.toIso8601String(),
        });
      });
}
