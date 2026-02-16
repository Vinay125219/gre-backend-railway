import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/mock/mock_database.dart';
import '../../domain/entities/test_entity.dart';
import '../../domain/repositories/test_repository.dart';

class TestRepositoryImpl implements TestRepository {
  final MockDatabase _db;

  TestRepositoryImpl({MockDatabase? database})
    : _db = database ?? MockDatabase();

  @override
  Future<Either<Failure, List<TestEntity>>> getTestsByCourse(
    String courseId,
  ) async {
    final tests =
        _db.tests
            .where((test) => test.courseId == courseId && test.published)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Right(tests);
  }

  @override
  Future<Either<Failure, List<TestEntity>>> getAvailableTests(
    String studentId,
  ) async {
    final enrolledCourseIds = _db.enrollments
        .where((enrollment) => enrollment.studentId == studentId)
        .map((enrollment) => enrollment.courseId)
        .toSet();

    final tests =
        _db.tests
            .where(
              (test) =>
                  test.published &&
                  (enrolledCourseIds.isEmpty ||
                      enrolledCourseIds.contains(test.courseId)),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Right(tests);
  }

  @override
  Future<Either<Failure, TestEntity>> getTestById(String testId) async {
    try {
      final test = _db.tests.firstWhere((item) => item.id == testId);
      return Right(test);
    } catch (_) {
      return const Left(NotFoundFailure(message: 'Test not found.'));
    }
  }

  @override
  Future<Either<Failure, List<QuestionEntity>>> getQuestions(
    String testId,
  ) async {
    final questions =
        _db.questions.where((question) => question.testId == testId).toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Right(questions);
  }

  @override
  Future<Either<Failure, TestAttemptEntity>> startAttempt(
    String testId,
    String studentId,
  ) async {
    final testExists = _db.tests.any((test) => test.id == testId);
    if (!testExists) {
      return const Left(NotFoundFailure(message: 'Test not found.'));
    }

    final attempt = TestAttemptEntity(
      id: 'attempt-${DateTime.now().microsecondsSinceEpoch}',
      testId: testId,
      studentId: studentId,
      status: AttemptStatus.inProgress,
      startedAt: DateTime.now(),
      answers: const {},
      markedForReview: const {},
      score: 0,
      totalMarks: 0,
      accuracy: 0,
      correctCount: 0,
      wrongCount: 0,
      unattemptedCount: 0,
      timeTaken: 0,
    );

    _db.attempts.add(attempt);
    return Right(attempt);
  }

  @override
  Future<Either<Failure, void>> saveAnswer(
    String attemptId,
    String questionId,
    dynamic answer,
  ) async {
    final index = _db.attempts.indexWhere((attempt) => attempt.id == attemptId);
    if (index < 0) {
      return const Left(NotFoundFailure(message: 'Attempt not found.'));
    }

    final existing = _db.attempts[index];
    final answers = Map<String, dynamic>.from(existing.answers);
    if (answer == null) {
      answers.remove(questionId);
    } else {
      answers[questionId] = answer;
    }

    _db.attempts[index] = TestAttemptEntity(
      id: existing.id,
      testId: existing.testId,
      studentId: existing.studentId,
      status: existing.status,
      startedAt: existing.startedAt,
      completedAt: existing.completedAt,
      answers: answers,
      markedForReview: existing.markedForReview,
      score: existing.score,
      totalMarks: existing.totalMarks,
      accuracy: existing.accuracy,
      correctCount: existing.correctCount,
      wrongCount: existing.wrongCount,
      unattemptedCount: existing.unattemptedCount,
      timeTaken: existing.timeTaken,
    );

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> toggleMarkForReview(
    String attemptId,
    String questionId,
    bool marked,
  ) async {
    final index = _db.attempts.indexWhere((attempt) => attempt.id == attemptId);
    if (index < 0) {
      return const Left(NotFoundFailure(message: 'Attempt not found.'));
    }

    final existing = _db.attempts[index];
    final markedForReview = Map<String, bool>.from(existing.markedForReview);
    markedForReview[questionId] = marked;

    _db.attempts[index] = TestAttemptEntity(
      id: existing.id,
      testId: existing.testId,
      studentId: existing.studentId,
      status: existing.status,
      startedAt: existing.startedAt,
      completedAt: existing.completedAt,
      answers: existing.answers,
      markedForReview: markedForReview,
      score: existing.score,
      totalMarks: existing.totalMarks,
      accuracy: existing.accuracy,
      correctCount: existing.correctCount,
      wrongCount: existing.wrongCount,
      unattemptedCount: existing.unattemptedCount,
      timeTaken: existing.timeTaken,
    );

    return const Right(null);
  }

  @override
  Future<Either<Failure, TestAttemptEntity>> submitAttempt(
    String attemptId,
  ) async {
    final attemptIndex = _db.attempts.indexWhere(
      (attempt) => attempt.id == attemptId,
    );
    if (attemptIndex < 0) {
      return const Left(NotFoundFailure(message: 'Attempt not found.'));
    }

    final attempt = _db.attempts[attemptIndex];
    final questions =
        _db.questions
            .where((question) => question.testId == attempt.testId)
            .toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    var correct = 0;
    var wrong = 0;
    var unattempted = 0;
    var score = 0;
    var totalMarks = 0;

    for (final question in questions) {
      totalMarks += question.marks;
      final answer = attempt.answers[question.id];
      if (answer == null || (answer is String && answer.trim().isEmpty)) {
        unattempted += 1;
        continue;
      }

      if (_isAnswerCorrect(question, answer)) {
        correct += 1;
        score += question.marks;
      } else {
        wrong += 1;
        score -= question.negativeMarks ?? 0;
      }
    }

    if (score < 0) {
      score = 0;
    }

    final completedAt = DateTime.now();
    final accuracy = questions.isEmpty
        ? 0.0
        : (correct / questions.length) * 100;
    final updated = TestAttemptEntity(
      id: attempt.id,
      testId: attempt.testId,
      studentId: attempt.studentId,
      status: AttemptStatus.completed,
      startedAt: attempt.startedAt,
      completedAt: completedAt,
      answers: attempt.answers,
      markedForReview: attempt.markedForReview,
      score: score,
      totalMarks: totalMarks,
      accuracy: accuracy,
      correctCount: correct,
      wrongCount: wrong,
      unattemptedCount: unattempted,
      timeTaken: completedAt.difference(attempt.startedAt).inSeconds,
    );

    _db.attempts[attemptIndex] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, TestAttemptEntity>> getAttempt(
    String attemptId,
  ) async {
    try {
      final attempt = _db.attempts.firstWhere((item) => item.id == attemptId);
      return Right(attempt);
    } catch (_) {
      return const Left(NotFoundFailure(message: 'Attempt not found.'));
    }
  }

  @override
  Future<Either<Failure, List<TestAttemptEntity>>> getStudentAttempts(
    String studentId,
  ) async {
    final attempts =
        _db.attempts.where((attempt) => attempt.studentId == studentId).toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return Right(attempts);
  }

  @override
  Future<Either<Failure, (TestAttemptEntity, List<QuestionEntity>)>>
  getAttemptWithQuestions(String attemptId) async {
    final attemptResult = await getAttempt(attemptId);
    if (attemptResult.isLeft()) {
      return Left(attemptResult.swap().getOrElse(() => const UnknownFailure()));
    }

    final attempt = attemptResult.getOrElse(
      () => throw StateError('Attempt missing'),
    );
    final questionsResult = await getQuestions(attempt.testId);
    if (questionsResult.isLeft()) {
      return Left(
        questionsResult.swap().getOrElse(() => const UnknownFailure()),
      );
    }

    final questions = questionsResult.getOrElse(() => const <QuestionEntity>[]);
    return Right((attempt, questions));
  }

  bool _isAnswerCorrect(QuestionEntity question, dynamic answer) {
    switch (question.type) {
      case QuestionType.mcq:
      case QuestionType.nat:
        final expected = question.correctAnswer.toString().trim().toLowerCase();
        final provided = answer.toString().trim().toLowerCase();

        if (question.type == QuestionType.nat) {
          final expectedNumeric = double.tryParse(expected);
          final providedNumeric = double.tryParse(provided);
          if (expectedNumeric != null && providedNumeric != null) {
            return (expectedNumeric - providedNumeric).abs() < 0.000001;
          }
        }

        return expected == provided;

      case QuestionType.msq:
        final expected = question.correctAnswer is List
            ? (question.correctAnswer as List)
                  .map((item) => item.toString())
                  .toSet()
            : {question.correctAnswer.toString()};

        final provided = answer is List
            ? answer.map((item) => item.toString()).toSet()
            : {answer.toString()};

        return expected.length == provided.length &&
            expected.containsAll(provided);
    }
  }
}
