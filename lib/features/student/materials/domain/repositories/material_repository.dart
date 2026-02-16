import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/material_entity.dart';

/// Material repository interface
abstract class MaterialRepository {
  /// Get all materials for a course
  Future<Either<Failure, List<MaterialEntity>>> getMaterialsByCourse(
    String courseId,
  );

  /// Get materials by section
  Future<Either<Failure, List<MaterialEntity>>> getMaterialsBySection(
    String courseId,
    String section,
  );

  /// Get material by ID
  Future<Either<Failure, MaterialEntity>> getMaterialById(String materialId);

  /// Get student's progress for a material
  Future<Either<Failure, MaterialProgressEntity?>> getProgress(
    String studentId,
    String materialId,
  );

  /// Update progress
  Future<Either<Failure, void>> updateProgress(MaterialProgressEntity progress);

  /// Mark material as completed
  Future<Either<Failure, void>> markCompleted(
    String studentId,
    String materialId,
  );
}
