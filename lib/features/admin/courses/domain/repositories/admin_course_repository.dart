import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';

abstract class AdminCourseRepository {
  /// Get all courses (published and unpublished)
  Future<Either<Failure, List<CourseEntity>>> getAllCourses();

  /// Create a new course
  Future<Either<Failure, void>> createCourse(CourseEntity course);

  /// Update an existing course
  Future<Either<Failure, void>> updateCourse(CourseEntity course);

  /// Delete a course
  Future<Either<Failure, void>> deleteCourse(String courseId);
}
