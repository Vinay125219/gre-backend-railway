import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../auth/domain/entities/user_entity.dart';

abstract class AdminStudentRepository {
  /// Get all students
  Future<Either<Failure, List<UserEntity>>> getAllStudents();

  /// Create a new student (Auth + Firestore Profile)
  Future<Either<Failure, UserEntity>> createStudent({
    required String email,
    required String password,
    required String name,
    List<String>? assignedCourses,
    DateTime? expiryDate,
  });

  /// Update student status (active/inactive) or courses
  Future<Either<Failure, void>> updateStudent(
    UserEntity student, {
    List<String>? assignedCourses,
    String? password,
  });

  /// Get assigned course IDs for a student
  Future<Either<Failure, List<String>>> getAssignedCourses(String studentId);
}
