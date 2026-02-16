import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/test_entity.dart';

/// Test repository interface
abstract class TestRepository {
  /// Get all available tests for a course
  Future<Either<Failure, List<TestEntity>>> getTestsByCourse(String courseId);

  /// Get all available tests for a student
  Future<Either<Failure, List<TestEntity>>> getAvailableTests(String studentId);

  /// Get test by ID
  Future<Either<Failure, TestEntity>> getTestById(String testId);

  /// Get questions for a test
  Future<Either<Failure, List<QuestionEntity>>> getQuestions(String testId);

  /// Start a new test attempt
  Future<Either<Failure, TestAttemptEntity>> startAttempt(
    String testId,
    String studentId,
  );

  /// Save answer for a question
  Future<Either<Failure, void>> saveAnswer(
    String attemptId,
    String questionId,
    dynamic answer,
  );

  /// Toggle mark for review
  Future<Either<Failure, void>> toggleMarkForReview(
    String attemptId,
    String questionId,
    bool marked,
  );

  /// Submit test attempt
  Future<Either<Failure, TestAttemptEntity>> submitAttempt(String attemptId);

  /// Get test attempt by ID
  Future<Either<Failure, TestAttemptEntity>> getAttempt(String attemptId);

  /// Get all attempts for a student
  Future<Either<Failure, List<TestAttemptEntity>>> getStudentAttempts(
    String studentId,
  );

  /// Get attempt with questions for results
  Future<Either<Failure, (TestAttemptEntity, List<QuestionEntity>)>>
  getAttemptWithQuestions(String attemptId);
}
