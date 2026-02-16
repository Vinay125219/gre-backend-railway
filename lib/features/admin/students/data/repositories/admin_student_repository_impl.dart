import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/mock/mock_database.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';
import '../../domain/repositories/admin_student_repository.dart';

class AdminStudentRepositoryImpl implements AdminStudentRepository {
  final MockDatabase _db;

  AdminStudentRepositoryImpl({MockDatabase? database})
    : _db = database ?? MockDatabase();

  @override
  Future<Either<Failure, List<UserEntity>>> getAllStudents() async {
    final students = _db.users.where((user) => user.role == 'student').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Right(students);
  }

  @override
  Future<Either<Failure, UserEntity>> createStudent({
    required String email,
    required String password,
    required String name,
    List<String>? assignedCourses,
    DateTime? expiryDate,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_db.users.any((user) => user.email.toLowerCase() == normalizedEmail)) {
      return const Left(ServerFailure(message: 'Email already in use.'));
    }

    if (password.length < 6) {
      return const Left(
        AuthFailure(message: 'Password must be at least 6 characters.'),
      );
    }

    final now = DateTime.now();
    final newUser = UserEntity(
      id: 'student-${now.microsecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: name.trim(),
      role: 'student',
      createdAt: now,
      lastLoginAt: now,
      expiryDate: expiryDate,
    );

    _db.users.add(newUser);
    _syncStudentEnrollments(newUser.id, assignedCourses ?? const []);

    return Right(newUser);
  }

  @override
  Future<Either<Failure, void>> updateStudent(
    UserEntity student, {
    List<String>? assignedCourses,
    String? password,
  }) async {
    final index = _db.users.indexWhere((user) => user.id == student.id);
    if (index < 0) {
      return const Left(NotFoundFailure(message: 'Student not found.'));
    }

    if (password != null && password.isNotEmpty && password.length < 6) {
      return const Left(
        AuthFailure(message: 'Password must be at least 6 characters.'),
      );
    }

    _db.users[index] = student;

    if (assignedCourses != null) {
      _syncStudentEnrollments(student.id, assignedCourses);
    }

    return const Right(null);
  }

  @override
  Future<Either<Failure, List<String>>> getAssignedCourses(
    String studentId,
  ) async {
    final courseIds =
        _db.enrollments
            .where((enrollment) => enrollment.studentId == studentId)
            .map((enrollment) => enrollment.courseId)
            .toSet()
            .toList()
          ..sort();

    return Right(courseIds);
  }

  void _syncStudentEnrollments(
    String studentId,
    List<String> requestedCourseIds,
  ) {
    final validCourseIds = requestedCourseIds
        .where((id) => _db.courses.any((course) => course.id == id))
        .toSet();

    _db.enrollments.removeWhere(
      (enrollment) =>
          enrollment.studentId == studentId &&
          !validCourseIds.contains(enrollment.courseId),
    );

    for (final courseId in validCourseIds) {
      final alreadyExists = _db.enrollments.any(
        (enrollment) =>
            enrollment.studentId == studentId &&
            enrollment.courseId == courseId,
      );
      if (alreadyExists) {
        continue;
      }

      _db.enrollments.add(
        EnrollmentEntity(
          id: 'enrollment-${DateTime.now().microsecondsSinceEpoch}',
          studentId: studentId,
          courseId: courseId,
          enrolledAt: DateTime.now(),
          progress: 0,
          completedMaterials: 0,
          completedTests: 0,
        ),
      );
    }
  }
}
