import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/mock/mock_database.dart';
import '../../../../student/tests/domain/entities/test_entity.dart';
import '../../domain/repositories/admin_test_repository.dart';

class AdminTestRepositoryImpl implements AdminTestRepository {
  final MockDatabase _db;

  AdminTestRepositoryImpl({MockDatabase? database})
    : _db = database ?? MockDatabase();

  @override
  Future<Either<Failure, List<TestEntity>>> getAllTests({
    String? courseId,
  }) async {
    final tests =
        _db.tests
            .where((test) => courseId == null || test.courseId == courseId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Right(tests);
  }

  @override
  Future<Either<Failure, TestEntity>> getTestById(String testId) async {
    try {
      final test = _db.tests.firstWhere((entry) => entry.id == testId);
      return Right(test);
    } catch (_) {
      return const Left(NotFoundFailure(message: 'Test not found.'));
    }
  }

  @override
  Future<Either<Failure, TestEntity>> createTest({
    required String courseId,
    required String title,
    required String description,
    required String section,
    required int duration,
    required bool shuffleQuestions,
    required bool showResults,
    required List<QuestionEntity> questions,
  }) async {
    final courseExists = _db.courses.any((course) => course.id == courseId);
    if (!courseExists) {
      return const Left(NotFoundFailure(message: 'Course not found.'));
    }

    final now = DateTime.now();
    final testId = 'test-${now.microsecondsSinceEpoch}';

    final normalizedQuestions = questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      return QuestionEntity(
        id: _generateQuestionId(question.id),
        testId: testId,
        orderIndex: index,
        type: question.type,
        question: question.question,
        passage: question.passage,
        options: question.options,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation,
        marks: question.marks,
        negativeMarks: question.negativeMarks,
      );
    }).toList();

    final test = TestEntity(
      id: testId,
      courseId: courseId,
      title: title.trim(),
      description: description.trim(),
      section: section.trim().toLowerCase(),
      duration: duration,
      totalQuestions: normalizedQuestions.length,
      totalMarks: normalizedQuestions.fold<int>(
        0,
        (sum, question) => sum + question.marks,
      ),
      published: false,
      shuffleQuestions: shuffleQuestions,
      createdAt: now,
    );

    _db.tests.add(test);
    _db.questions.addAll(normalizedQuestions);
    return Right(test);
  }

  @override
  Future<Either<Failure, void>> updateTest(TestEntity test) async {
    final index = _db.tests.indexWhere((entry) => entry.id == test.id);
    if (index < 0) {
      return const Left(NotFoundFailure(message: 'Test not found.'));
    }

    final existing = _db.tests[index];
    _db.tests[index] = _rebuildTest(
      source: test,
      createdAt: existing.createdAt,
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteTest(String testId) async {
    final exists = _db.tests.any((test) => test.id == testId);
    if (!exists) {
      return const Left(NotFoundFailure(message: 'Test not found.'));
    }

    _db.tests.removeWhere((test) => test.id == testId);
    _db.questions.removeWhere((question) => question.testId == testId);
    _db.attempts.removeWhere((attempt) => attempt.testId == testId);

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> setTestPublished(
    String testId,
    bool published,
  ) async {
    final index = _db.tests.indexWhere((test) => test.id == testId);
    if (index < 0) {
      return const Left(NotFoundFailure(message: 'Test not found.'));
    }

    final existing = _db.tests[index];
    _db.tests[index] = _rebuildTest(source: existing, published: published);

    return const Right(null);
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
  Future<Either<Failure, QuestionEntity>> addQuestion({
    required String testId,
    required QuestionEntity question,
  }) async {
    final testExists = _db.tests.any((test) => test.id == testId);
    if (!testExists) {
      return const Left(NotFoundFailure(message: 'Test not found.'));
    }

    final currentQuestions = _db.questions
        .where((entry) => entry.testId == testId)
        .toList();

    final created = QuestionEntity(
      id: _generateQuestionId(question.id),
      testId: testId,
      orderIndex: currentQuestions.length,
      type: question.type,
      question: question.question,
      passage: question.passage,
      options: question.options,
      correctAnswer: question.correctAnswer,
      explanation: question.explanation,
      marks: question.marks,
      negativeMarks: question.negativeMarks,
    );

    _db.questions.add(created);
    _recalculateTestSummary(testId);

    return Right(created);
  }

  @override
  Future<Either<Failure, void>> updateQuestion(QuestionEntity question) async {
    final index = _db.questions.indexWhere((entry) => entry.id == question.id);
    if (index < 0) {
      return const Left(NotFoundFailure(message: 'Question not found.'));
    }

    _db.questions[index] = question;
    _recalculateTestSummary(question.testId);

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteQuestion(
    String testId,
    String questionId,
  ) async {
    final index = _db.questions.indexWhere(
      (entry) => entry.id == questionId && entry.testId == testId,
    );

    if (index < 0) {
      return const Left(NotFoundFailure(message: 'Question not found.'));
    }

    _db.questions.removeAt(index);
    _recalculateQuestionOrder(testId);
    _recalculateTestSummary(testId);

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reorderQuestions(
    String testId,
    List<String> questionIds,
  ) async {
    final questions = _db.questions
        .where((question) => question.testId == testId)
        .toList();

    if (questions.length != questionIds.length) {
      return const Left(ValidationFailure(message: 'Question list mismatch.'));
    }

    final byId = {for (final question in questions) question.id: question};
    for (var i = 0; i < questionIds.length; i++) {
      final question = byId[questionIds[i]];
      if (question == null) {
        return const Left(
          ValidationFailure(message: 'Invalid question order.'),
        );
      }

      final index = _db.questions.indexWhere(
        (entry) => entry.id == question.id,
      );
      _db.questions[index] = QuestionEntity(
        id: question.id,
        testId: question.testId,
        orderIndex: i,
        type: question.type,
        question: question.question,
        passage: question.passage,
        options: question.options,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation,
        marks: question.marks,
        negativeMarks: question.negativeMarks,
      );
    }

    _recalculateTestSummary(testId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, TestStats>> getTestStats(String testId) async {
    final attempts = _db.attempts
        .where(
          (attempt) =>
              attempt.testId == testId &&
              attempt.status == AttemptStatus.completed,
        )
        .toList();

    if (attempts.isEmpty) {
      return Right(TestStats.empty());
    }

    final scorePercentages = attempts.map((attempt) {
      if (attempt.totalMarks <= 0) return 0.0;
      return (attempt.score / attempt.totalMarks) * 100;
    }).toList();

    final avgScore =
        scorePercentages.reduce((a, b) => a + b) / scorePercentages.length;
    final avgAccuracy =
        attempts.map((attempt) => attempt.accuracy).reduce((a, b) => a + b) /
        attempts.length;

    final highest = scorePercentages.reduce((a, b) => a > b ? a : b);
    final lowest = scorePercentages.reduce((a, b) => a < b ? a : b);
    final passCount = scorePercentages.where((score) => score >= 50).length;
    final failCount = scorePercentages.length - passCount;

    return Right(
      TestStats(
        totalAttempts: attempts.length,
        averageScore: avgScore,
        averageAccuracy: avgAccuracy,
        passCount: passCount,
        failCount: failCount,
        highestScore: highest,
        lowestScore: lowest,
      ),
    );
  }

  void _recalculateQuestionOrder(String testId) {
    final ordered =
        _db.questions.where((question) => question.testId == testId).toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (var i = 0; i < ordered.length; i++) {
      final question = ordered[i];
      final index = _db.questions.indexWhere(
        (entry) => entry.id == question.id,
      );
      _db.questions[index] = QuestionEntity(
        id: question.id,
        testId: question.testId,
        orderIndex: i,
        type: question.type,
        question: question.question,
        passage: question.passage,
        options: question.options,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation,
        marks: question.marks,
        negativeMarks: question.negativeMarks,
      );
    }
  }

  void _recalculateTestSummary(String testId) {
    final testIndex = _db.tests.indexWhere((test) => test.id == testId);
    if (testIndex < 0) {
      return;
    }

    final questions = _db.questions.where(
      (question) => question.testId == testId,
    );
    final totalQuestions = questions.length;
    final totalMarks = questions.fold<int>(0, (sum, item) => sum + item.marks);

    final test = _db.tests[testIndex];
    _db.tests[testIndex] = _rebuildTest(
      source: test,
      totalQuestions: totalQuestions,
      totalMarks: totalMarks,
    );
  }

  String _generateQuestionId(String preferredId) {
    var candidate = preferredId.trim();
    if (candidate.isEmpty ||
        _db.questions.any((question) => question.id == candidate)) {
      candidate = 'question-${DateTime.now().microsecondsSinceEpoch}';
    }
    return candidate;
  }

  TestEntity _rebuildTest({
    required TestEntity source,
    DateTime? createdAt,
    bool? published,
    int? totalQuestions,
    int? totalMarks,
  }) {
    return TestEntity(
      id: source.id,
      courseId: source.courseId,
      title: source.title,
      description: source.description,
      section: source.section,
      duration: source.duration,
      totalQuestions: totalQuestions ?? source.totalQuestions,
      totalMarks: totalMarks ?? source.totalMarks,
      published: published ?? source.published,
      shuffleQuestions: source.shuffleQuestions,
      availableFrom: source.availableFrom,
      availableUntil: source.availableUntil,
      createdAt: createdAt ?? source.createdAt,
    );
  }
}
