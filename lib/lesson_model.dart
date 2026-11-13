class Question {
  const Question(this.prompt, this.choices, this.answer, this.feedback);
  final String prompt;
  final List<String> choices;
  final int answer;
  final List<String> feedback;
}

class Lesson {
  const Lesson(
    this.id,
    this.subject,
    this.title,
    this.goal,
    this.example,
    this.questions,
  );
  final String id, subject, title, goal, example;
  String get subjectId => id.split('.').first;
  final List<Question> questions;
}

typedef Check = ({bool correct, String feedback});

Check grade(Question q, String input) {
  if (q.choices.isNotEmpty) {
    final index = int.tryParse(input);
    if (index == null || index < 0 || index >= q.choices.length) {
      return (correct: false, feedback: 'Elige una respuesta disponible.');
    }
    return (correct: index == q.answer, feedback: q.feedback[index]);
  }
  final ops = <String, bool Function(int)>{
    '>=': (x) => x >= 0,
    '>': (x) => x > 0,
    '<': (x) => x < 0,
    '<=': (x) => x <= 0,
    '==': (x) => x == 0,
    '!=': (x) => x != 0,
  };
  final op = ops[input.trim()];
  if (op == null) {
    return (
      correct: false,
      feedback: 'Escribe un operador de comparación de Python, como > o >=. El hueco compara x con 0.',
    );
  }
  for (final sample in [
    <int>[],
    [0],
    [-1, 2, 4],
    [-2, 0, 3],
  ]) {
    final expected = sample.where((x) => x >= 0).length;
    final actual = sample.where(op).length;
    if (actual != expected) {
      return (
        correct: false,
        feedback:
            'Con $sample tu condición cuenta $actual. Esperábamos $expected. Incluye cero y positivos y excluye negativos.',
      );
    }
  }
  return (
    correct: true,
    feedback: 'Las cuatro pruebas pasan, incluida la lista vacía y el caso [0]. El operador >= incluye el límite.',
  );
}
