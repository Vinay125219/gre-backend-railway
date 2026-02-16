import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/mock/mock_database.dart';
import '../../../tests/domain/entities/test_entity.dart';
import '../../domain/entities/performance_entity.dart';
import '../../domain/repositories/performance_repository.dart';

class PerformanceRepositoryImpl implements PerformanceRepository {
  final MockDatabase _db;

  PerformanceRepositoryImpl({MockDatabase? database})
    : _db = database ?? MockDatabase();

  @override
  Future<Either<Failure, PerformanceEntity>> getStudentPerformance(
    String studentId,
  ) async {
    return Right(_buildPerformance(studentId: studentId));
  }

  @override
  Future<Either<Failure, PerformanceEntity>> getPerformanceByDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return Right(
      _buildPerformance(
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  PerformanceEntity _buildPerformance({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final attempts =
        _db.attempts
            .where(
              (attempt) =>
                  attempt.studentId == studentId &&
                  attempt.status == AttemptStatus.completed,
            )
            .where((attempt) {
              final completedAt = attempt.completedAt ?? attempt.startedAt;
              if (startDate != null && completedAt.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && completedAt.isAfter(endDate)) {
                return false;
              }
              return true;
            })
            .toList()
          ..sort((a, b) {
            final aDate = a.completedAt ?? a.startedAt;
            final bDate = b.completedAt ?? b.startedAt;
            return bDate.compareTo(aDate);
          });

    if (attempts.isEmpty) {
      return PerformanceEntity(studentId: studentId);
    }

    var totalCorrect = 0;
    var totalWrong = 0;
    var totalUnattempted = 0;
    var totalTimeTaken = 0;

    final sectionBuckets = <String, _SectionAccumulator>{};

    for (final attempt in attempts) {
      totalCorrect += attempt.correctCount;
      totalWrong += attempt.wrongCount;
      totalUnattempted += attempt.unattemptedCount;
      totalTimeTaken += attempt.timeTaken;

      final test = _findTest(attempt.testId);
      final section = _sectionLabel(test?.section ?? 'general');
      final bucket = sectionBuckets.putIfAbsent(
        section,
        _SectionAccumulator.new,
      );
      bucket.attempts += 1;
      bucket.accuracySum += attempt.accuracy;
      bucket.timeSum += attempt.timeTaken;
    }

    final totalAnswered = totalCorrect + totalWrong + totalUnattempted;
    final overallAccuracy = totalAnswered == 0
        ? 0.0
        : (totalCorrect / totalAnswered) * 100;

    final recentScores = attempts.map((attempt) {
      final test = _findTest(attempt.testId);
      return TestScore(
        testId: attempt.testId,
        testTitle: test?.title ?? 'Mock Test',
        section: _sectionLabel(test?.section ?? 'general'),
        score: attempt.score,
        totalMarks: attempt.totalMarks,
        accuracy: attempt.accuracy,
        attemptedAt: attempt.completedAt ?? attempt.startedAt,
      );
    }).toList();

    final sectionPerformance = <String, SectionPerformance>{};
    sectionBuckets.forEach((section, data) {
      sectionPerformance[section] = SectionPerformance(
        section: section,
        attempts: data.attempts,
        accuracy: data.attempts == 0 ? 0 : data.accuracySum / data.attempts,
        avgTimeTaken: data.attempts == 0
            ? 0
            : (data.timeSum / data.attempts).round(),
        strongTopics: _strongTopicsForSection(section),
        weakTopics: _weakTopicsForSection(section),
      );
    });

    return PerformanceEntity(
      studentId: studentId,
      totalTests: attempts.map((attempt) => attempt.testId).toSet().length,
      totalAttempts: attempts.length,
      overallAccuracy: overallAccuracy,
      verbalAccuracy: sectionPerformance['Verbal Reasoning']?.accuracy ?? 0,
      quantAccuracy:
          sectionPerformance['Quantitative Reasoning']?.accuracy ?? 0,
      awaAccuracy: sectionPerformance['Analytical Writing']?.accuracy ?? 0,
      totalCorrect: totalCorrect,
      totalWrong: totalWrong,
      totalUnattempted: totalUnattempted,
      totalTimeTaken: totalTimeTaken,
      recentScores: recentScores,
      sectionPerformance: sectionPerformance,
    );
  }

  TestEntity? _findTest(String testId) {
    for (final test in _db.tests) {
      if (test.id == testId) {
        return test;
      }
    }
    return null;
  }

  String _sectionLabel(String rawSection) {
    switch (rawSection.trim().toLowerCase()) {
      case 'verbal':
      case 'verbal reasoning':
        return 'Verbal Reasoning';
      case 'quant':
      case 'quantitative reasoning':
        return 'Quantitative Reasoning';
      case 'awa':
      case 'analytical writing':
        return 'Analytical Writing';
      default:
        return 'General';
    }
  }

  List<String> _strongTopicsForSection(String section) {
    switch (section) {
      case 'Verbal Reasoning':
        return const ['Text Completion', 'Sentence Equivalence'];
      case 'Quantitative Reasoning':
        return const ['Arithmetic', 'Algebra'];
      case 'Analytical Writing':
        return const ['Essay Structure', 'Clarity'];
      default:
        return const [];
    }
  }

  List<String> _weakTopicsForSection(String section) {
    switch (section) {
      case 'Verbal Reasoning':
        return const ['Long Passages'];
      case 'Quantitative Reasoning':
        return const ['Data Interpretation'];
      case 'Analytical Writing':
        return const ['Examples and Evidence'];
      default:
        return const [];
    }
  }
}

class _SectionAccumulator {
  int attempts = 0;
  double accuracySum = 0;
  int timeSum = 0;
}
