import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/performance_entity.dart';

/// Repository interface for student performance analytics
abstract class PerformanceRepository {
  /// Get overall performance data for a student
  Future<Either<Failure, PerformanceEntity>> getStudentPerformance(
    String studentId,
  );

  /// Get performance filtered by date range
  Future<Either<Failure, PerformanceEntity>> getPerformanceByDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  );
}
