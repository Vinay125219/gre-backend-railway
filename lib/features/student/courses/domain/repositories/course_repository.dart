import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/course_entity.dart';

/// Course repository interface
abstract class CourseRepository {
  /// Get all enrolled courses for a student
  Future<Either<Failure, List<CourseEntity>>> getEnrolledCourses(
    String studentId,
  );

  /// Get course details by ID
  Future<Either<Failure, CourseEntity>> getCourseById(String courseId);

  /// Watch enrolled courses (real-time)
  Stream<List<CourseEntity>> watchEnrolledCourses(String studentId);

  /// Get enrollment progress for a course
  Future<Either<Failure, EnrollmentEntity>> getEnrollment(
    String studentId,
    String courseId,
  );

  /// Update enrollment progress
  Future<Either<Failure, void>> updateProgress(
    String studentId,
    String courseId,
    double progress,
  );
}
