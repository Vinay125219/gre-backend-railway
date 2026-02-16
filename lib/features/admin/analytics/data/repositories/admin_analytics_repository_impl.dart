import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/mock/mock_database.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../student/tests/domain/entities/test_entity.dart';
import '../../domain/entities/analytics_overview_entity.dart';
import '../../domain/repositories/admin_analytics_repository.dart';

class AdminAnalyticsRepositoryImpl implements AdminAnalyticsRepository {
  final MockDatabase _db;

  AdminAnalyticsRepositoryImpl({MockDatabase? database})
    : _db = database ?? MockDatabase();

  @override
  Future<Either<Failure, AnalyticsOverviewEntity>>
  getAnalyticsOverview() async {
    final students = _db.users.where((user) => user.role == 'student').toList();
    final completedAttempts = _db.attempts
        .where((attempt) => attempt.status == AttemptStatus.completed)
        .toList();

    final avgAccuracy = completedAttempts.isEmpty
        ? 0.0
        : completedAttempts
                  .map((attempt) => attempt.accuracy)
                  .reduce((a, b) => a + b) /
              completedAttempts.length;

    final activeStudents = _activeStudentsCount(students, completedAttempts);

    final sectionPerformance = _sectionPerformance(completedAttempts);
    final distribution = _performanceDistribution(completedAttempts);
    final topStudents = _topStudents(students, completedAttempts);

    return Right(
      AnalyticsOverviewEntity(
        totalStudents: students.length,
        activeStudents: activeStudents,
        testsCompleted: completedAttempts.length,
        avgAccuracy: avgAccuracy,
        activityData: _last7DayActivity(completedAttempts),
        topStudents: topStudents,
        sectionPerformance: sectionPerformance,
        performanceDistribution: distribution,
      ),
    );
  }

  int _activeStudentsCount(
    List<UserEntity> students,
    List<TestAttemptEntity> completedAttempts,
  ) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final activeByAttempts = completedAttempts
        .where(
          (attempt) =>
              (attempt.completedAt ?? attempt.startedAt).isAfter(cutoff),
        )
        .map((attempt) => attempt.studentId)
        .toSet();

    final activeByLogin = students
        .where(
          (student) =>
              (student.lastLoginAt ?? student.createdAt).isAfter(cutoff),
        )
        .map((student) => student.id)
        .toSet();

    return {...activeByAttempts, ...activeByLogin}.length;
  }

  List<double> _last7DayActivity(List<TestAttemptEntity> completedAttempts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));

    return List<double>.generate(7, (index) {
      final dayStart = start.add(Duration(days: index));
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = completedAttempts.where((attempt) {
        final completedAt = attempt.completedAt ?? attempt.startedAt;
        return !completedAt.isBefore(dayStart) && completedAt.isBefore(dayEnd);
      }).length;

      return count.toDouble();
    });
  }

  List<StudentPerformanceEntity> _topStudents(
    List<UserEntity> students,
    List<TestAttemptEntity> completedAttempts,
  ) {
    final byStudent = <String, List<TestAttemptEntity>>{};

    for (final attempt in completedAttempts) {
      byStudent.putIfAbsent(attempt.studentId, () => []).add(attempt);
    }

    final result = <StudentPerformanceEntity>[];

    byStudent.forEach((studentId, attempts) {
      attempts.sort((a, b) {
        final aDate = a.completedAt ?? a.startedAt;
        final bDate = b.completedAt ?? b.startedAt;
        return aDate.compareTo(bDate);
      });

      final student = students
          .where((user) => user.id == studentId)
          .firstOrNull;
      final avgScore =
          attempts
              .map((attempt) {
                if (attempt.totalMarks <= 0) {
                  return 0.0;
                }
                return (attempt.score / attempt.totalMarks) * 100;
              })
              .reduce((a, b) => a + b) /
          attempts.length;

      final trendValue = attempts.length < 2
          ? 0.0
          : attempts.last.accuracy - attempts.first.accuracy;
      final trend =
          '${trendValue >= 0 ? '+' : ''}${trendValue.toStringAsFixed(1)}%';

      result.add(
        StudentPerformanceEntity(
          id: studentId,
          name: student?.displayName ?? 'Student',
          avgScore: avgScore,
          trend: trend,
        ),
      );
    });

    result.sort((a, b) => b.avgScore.compareTo(a.avgScore));
    return result.take(5).toList();
  }

  Map<String, double> _sectionPerformance(List<TestAttemptEntity> attempts) {
    final testById = {for (final test in _db.tests) test.id: test};
    final sectionValues = <String, List<double>>{
      'Verbal Reasoning': [],
      'Quantitative Reasoning': [],
      'Analytical Writing': [],
    };

    for (final attempt in attempts) {
      final test = testById[attempt.testId];
      final section = _sectionLabel(test?.section ?? 'general');
      sectionValues.putIfAbsent(section, () => []).add(attempt.accuracy);
    }

    final result = <String, double>{};
    sectionValues.forEach((section, values) {
      if (values.isEmpty) {
        result[section] = 0;
      } else {
        final avg = values.reduce((a, b) => a + b) / values.length;
        result[section] = avg;
      }
    });

    return result;
  }

  Map<String, double> _performanceDistribution(
    List<TestAttemptEntity> attempts,
  ) {
    var excellent = 0.0;
    var average = 0.0;
    var needsWork = 0.0;

    for (final attempt in attempts) {
      if (attempt.accuracy >= 80) {
        excellent += 1;
      } else if (attempt.accuracy >= 50) {
        average += 1;
      } else {
        needsWork += 1;
      }
    }

    return {
      'Excellent': excellent,
      'Average': average,
      'Needs Work': needsWork,
    };
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
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
