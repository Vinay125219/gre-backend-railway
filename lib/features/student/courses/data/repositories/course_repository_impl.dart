import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/mock/mock_database.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';

class CourseRepositoryImpl implements CourseRepository {
  final MockDatabase _db;

  CourseRepositoryImpl({MockDatabase? database})
    : _db = database ?? MockDatabase();

  @override
  Future<Either<Failure, List<CourseEntity>>> getEnrolledCourses(
    String studentId,
  ) async {
    final enrolledCourseIds = _db.enrollments
        .where((enrollment) => enrollment.studentId == studentId)
        .map((enrollment) => enrollment.courseId)
        .toSet();

    final courses =
        (enrolledCourseIds.isEmpty
                ? _db.courses.where((course) => course.published)
                : _db.courses.where(
                    (course) => enrolledCourseIds.contains(course.id),
                  ))
            .map(_withComputedCounts)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Right(courses);
  }

  @override
  Future<Either<Failure, CourseEntity>> getCourseById(String courseId) async {
    try {
      final course = _db.courses.firstWhere((item) => item.id == courseId);
      return Right(_withComputedCounts(course));
    } catch (_) {
      return const Left(NotFoundFailure(message: 'Course not found.'));
    }
  }

  @override
  Stream<List<CourseEntity>> watchEnrolledCourses(String studentId) async* {
    final result = await getEnrolledCourses(studentId);
    yield result.getOrElse(() => const <CourseEntity>[]);
  }

  @override
  Future<Either<Failure, EnrollmentEntity>> getEnrollment(
    String studentId,
    String courseId,
  ) async {
    try {
      final enrollment = _db.enrollments.firstWhere(
        (item) => item.studentId == studentId && item.courseId == courseId,
      );
      return Right(enrollment);
    } catch (_) {
      return const Left(NotFoundFailure(message: 'Enrollment not found.'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProgress(
    String studentId,
    String courseId,
    double progress,
  ) async {
    final clamped = progress.clamp(0.0, 1.0);
    final index = _db.enrollments.indexWhere(
      (item) => item.studentId == studentId && item.courseId == courseId,
    );

    if (index >= 0) {
      final existing = _db.enrollments[index];
      _db.enrollments[index] = EnrollmentEntity(
        id: existing.id,
        studentId: existing.studentId,
        courseId: existing.courseId,
        enrolledAt: existing.enrolledAt,
        progress: clamped,
        completedMaterials: existing.completedMaterials,
        completedTests: existing.completedTests,
      );
      return const Right(null);
    }

    _db.enrollments.add(
      EnrollmentEntity(
        id: 'enrollment-${DateTime.now().microsecondsSinceEpoch}',
        studentId: studentId,
        courseId: courseId,
        enrolledAt: DateTime.now(),
        progress: clamped,
        completedMaterials: 0,
        completedTests: 0,
      ),
    );

    return const Right(null);
  }

  CourseEntity _withComputedCounts(CourseEntity course) {
    final materialCount = _db.contentItems
        .where((item) => item.courseId == course.id)
        .length;
    final testCount = _db.tests
        .where((test) => test.courseId == course.id)
        .length;

    return course.copyWith(materialCount: materialCount, testCount: testCount);
  }
}
