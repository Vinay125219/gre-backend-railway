import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../student/tests/domain/entities/test_entity.dart';

/// Repository interface for admin test management
abstract class AdminTestRepository {
  /// Get all tests (optionally filtered by course)
  Future<Either<Failure, List<TestEntity>>> getAllTests({String? courseId});

  /// Get a single test by ID
  Future<Either<Failure, TestEntity>> getTestById(String testId);

  /// Create a new test with questions
  Future<Either<Failure, TestEntity>> createTest({
    required String courseId,
    required String title,
    required String description,
    required String section,
    required int duration,
    required bool shuffleQuestions,
    required bool showResults,
    required List<QuestionEntity> questions,
  });

  /// Update test details
  Future<Either<Failure, void>> updateTest(TestEntity test);

  /// Delete a test and its questions
  Future<Either<Failure, void>> deleteTest(String testId);

  /// Publish/unpublish a test
  Future<Either<Failure, void>> setTestPublished(String testId, bool published);

  /// Get all questions for a test
  Future<Either<Failure, List<QuestionEntity>>> getQuestions(String testId);

  /// Add a question to a test
  Future<Either<Failure, QuestionEntity>> addQuestion({
    required String testId,
    required QuestionEntity question,
  });

  /// Update a question
  Future<Either<Failure, void>> updateQuestion(QuestionEntity question);

  /// Delete a question
  Future<Either<Failure, void>> deleteQuestion(
    String testId,
    String questionId,
  );

  /// Reorder questions
  Future<Either<Failure, void>> reorderQuestions(
    String testId,
    List<String> questionIds,
  );

  /// Get test statistics (attempts count, average score, etc.)
  Future<Either<Failure, TestStats>> getTestStats(String testId);
}

/// Test statistics model
class TestStats {
  final int totalAttempts;
  final double averageScore;
  final double averageAccuracy;
  final int passCount;
  final int failCount;
  final double highestScore;
  final double lowestScore;

  const TestStats({
    required this.totalAttempts,
    required this.averageScore,
    required this.averageAccuracy,
    required this.passCount,
    required this.failCount,
    required this.highestScore,
    required this.lowestScore,
  });

  factory TestStats.empty() => const TestStats(
    totalAttempts: 0,
    averageScore: 0,
    averageAccuracy: 0,
    passCount: 0,
    failCount: 0,
    highestScore: 0,
    lowestScore: 0,
  );
}
