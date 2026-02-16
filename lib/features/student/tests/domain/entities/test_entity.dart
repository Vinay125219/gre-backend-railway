import 'package:equatable/equatable.dart';

/// Question types for GRE
enum QuestionType { mcq, msq, nat }

/// Test entity for domain layer
class TestEntity extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String section; // Verbal, Quant, AWA
  final int duration; // Duration in minutes
  final int totalQuestions;
  final int totalMarks;
  final bool published;
  final bool shuffleQuestions;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime createdAt;

  const TestEntity({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.section,
    required this.duration,
    required this.totalQuestions,
    required this.totalMarks,
    required this.published,
    this.shuffleQuestions = false,
    this.availableFrom,
    this.availableUntil,
    required this.createdAt,
  });

  /// Check if test is currently available
  bool get isAvailable {
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) return false;
    if (availableUntil != null && now.isAfter(availableUntil!)) return false;
    return published;
  }

  /// Get formatted duration
  String get formattedDuration {
    if (duration >= 60) {
      final hours = duration ~/ 60;
      final mins = duration % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${duration}m';
  }

  @override
  List<Object?> get props => [
    id,
    courseId,
    title,
    description,
    section,
    duration,
    totalQuestions,
    totalMarks,
    published,
    shuffleQuestions,
    availableFrom,
    availableUntil,
    createdAt,
  ];
}

/// Question entity
class QuestionEntity extends Equatable {
  final String id;
  final String testId;
  final int orderIndex;
  final QuestionType type;
  final String question;
  final String? passage; // Reading comprehension passage
  final List<String> options; // For MCQ/MSQ
  final dynamic correctAnswer; // String for MCQ/NAT, List<String> for MSQ
  final String? explanation;
  final int marks;
  final int? negativeMarks;

  const QuestionEntity({
    required this.id,
    required this.testId,
    required this.orderIndex,
    required this.type,
    required this.question,
    this.passage,
    this.options = const [],
    required this.correctAnswer,
    this.explanation,
    this.marks = 1,
    this.negativeMarks,
  });

  /// Get type display name
  String get typeName {
    switch (type) {
      case QuestionType.mcq:
        return 'Multiple Choice';
      case QuestionType.msq:
        return 'Multiple Select';
      case QuestionType.nat:
        return 'Numeric Answer';
    }
  }

  @override
  List<Object?> get props => [
    id,
    testId,
    orderIndex,
    type,
    question,
    passage,
    options,
    correctAnswer,
    explanation,
    marks,
    negativeMarks,
  ];
}

/// Test attempt status
enum AttemptStatus { inProgress, completed, expired }

/// Test attempt entity
class TestAttemptEntity extends Equatable {
  final String id;
  final String testId;
  final String studentId;
  final AttemptStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> answers; // questionId -> answer
  final Map<String, bool> markedForReview; // questionId -> reviewed
  final int score;
  final int totalMarks;
  final double accuracy;
  final int correctCount;
  final int wrongCount;
  final int unattemptedCount;
  final int timeTaken; // In seconds

  const TestAttemptEntity({
    required this.id,
    required this.testId,
    required this.studentId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.answers = const {},
    this.markedForReview = const {},
    this.score = 0,
    this.totalMarks = 0,
    this.accuracy = 0.0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.unattemptedCount = 0,
    this.timeTaken = 0,
  });

  /// Check if question is answered
  bool isAnswered(String questionId) => answers.containsKey(questionId);

  /// Check if question is marked for review
  bool isMarkedForReview(String questionId) =>
      markedForReview[questionId] ?? false;

  /// Get formatted time taken
  String get formattedTimeTaken {
    final hours = timeTaken ~/ 3600;
    final mins = (timeTaken % 3600) ~/ 60;
    final secs = timeTaken % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m ${secs}s';
    }
    if (mins > 0) {
      return '${mins}m ${secs}s';
    }
    return '${secs}s';
  }

  @override
  List<Object?> get props => [
    id,
    testId,
    studentId,
    status,
    startedAt,
    completedAt,
    answers,
    markedForReview,
    score,
    totalMarks,
    accuracy,
    correctCount,
    wrongCount,
    unattemptedCount,
    timeTaken,
  ];
}
