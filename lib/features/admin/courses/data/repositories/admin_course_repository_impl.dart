import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/mock/mock_database.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';
import '../../domain/repositories/admin_course_repository.dart';

class AdminCourseRepositoryImpl implements AdminCourseRepository {
  final MockDatabase _db;

  AdminCourseRepositoryImpl({MockDatabase? database})
    : _db = database ?? MockDatabase();

  @override
  Future<Either<Failure, List<CourseEntity>>> getAllCourses() async {
    final courses =
        _db.courses
            .map(
              (course) => course.copyWith(
                materialCount: _db.contentItems
                    .where((item) => item.courseId == course.id)
                    .length,
                testCount: _db.tests
                    .where((test) => test.courseId == course.id)
                    .length,
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Right(courses);
  }

  @override
  Future<Either<Failure, void>> createCourse(CourseEntity course) async {
    final generatedId = _ensureUniqueCourseId(course.id);
    final now = DateTime.now();

    _db.courses.add(
      course.copyWith(
        id: generatedId,
        createdAt: now,
        updatedAt: now,
        materialCount: 0,
        testCount: 0,
      ),
    );

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateCourse(CourseEntity course) async {
    final index = _db.courses.indexWhere((item) => item.id == course.id);
    if (index < 0) {
      return const Left(NotFoundFailure(message: 'Course not found.'));
    }

    final existing = _db.courses[index];
    _db.courses[index] = course.copyWith(
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      materialCount: _db.contentItems
          .where((item) => item.courseId == course.id)
          .length,
      testCount: _db.tests.where((test) => test.courseId == course.id).length,
    );

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteCourse(String courseId) async {
    final exists = _db.courses.any((course) => course.id == courseId);
    if (!exists) {
      return const Left(NotFoundFailure(message: 'Course not found.'));
    }
    _db.courses.removeWhere((course) => course.id == courseId);

    final deletedTestIds = _db.tests
        .where((test) => test.courseId == courseId)
        .map((test) => test.id)
        .toSet();

    _db.tests.removeWhere((test) => test.courseId == courseId);
    _db.questions.removeWhere(
      (question) => deletedTestIds.contains(question.testId),
    );
    _db.attempts.removeWhere(
      (attempt) => deletedTestIds.contains(attempt.testId),
    );
    _db.contentItems.removeWhere((item) => item.courseId == courseId);
    _db.enrollments.removeWhere(
      (enrollment) => enrollment.courseId == courseId,
    );

    return const Right(null);
  }

  String _ensureUniqueCourseId(String preferredId) {
    var candidate = preferredId.trim();
    if (candidate.isEmpty) {
      candidate = 'course-${DateTime.now().millisecondsSinceEpoch}';
    }

    if (!_db.courses.any((course) => course.id == candidate)) {
      return candidate;
    }

    return '$candidate-${DateTime.now().microsecondsSinceEpoch}';
  }
}
