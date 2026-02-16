import 'package:equatable/equatable.dart';

/// Performance entity for analytics
class PerformanceEntity extends Equatable {
  final String studentId;
  final int totalTests;
  final int totalAttempts;
  final double overallAccuracy;
  final double verbalAccuracy;
  final double quantAccuracy;
  final double awaAccuracy;
  final int totalCorrect;
  final int totalWrong;
  final int totalUnattempted;
  final int totalTimeTaken; // in seconds
  final List<TestScore> recentScores;
  final Map<String, SectionPerformance> sectionPerformance;

  const PerformanceEntity({
    required this.studentId,
    this.totalTests = 0,
    this.totalAttempts = 0,
    this.overallAccuracy = 0.0,
    this.verbalAccuracy = 0.0,
    this.quantAccuracy = 0.0,
    this.awaAccuracy = 0.0,
    this.totalCorrect = 0,
    this.totalWrong = 0,
    this.totalUnattempted = 0,
    this.totalTimeTaken = 0,
    this.recentScores = const [],
    this.sectionPerformance = const {},
  });

  /// Get formatted total time
  String get formattedTotalTime {
    final hours = totalTimeTaken ~/ 3600;
    final mins = (totalTimeTaken % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }

  /// Get improvement trend (based on last 5 tests)
  double get improvementTrend {
    if (recentScores.length < 2) return 0.0;
    final recent = recentScores.take(5).toList();
    if (recent.length < 2) return 0.0;
    return recent.first.accuracy - recent.last.accuracy;
  }

  @override
  List<Object?> get props => [
    studentId,
    totalTests,
    totalAttempts,
    overallAccuracy,
    verbalAccuracy,
    quantAccuracy,
    awaAccuracy,
    totalCorrect,
    totalWrong,
    totalUnattempted,
    totalTimeTaken,
    recentScores,
    sectionPerformance,
  ];
}

/// Individual test score
class TestScore extends Equatable {
  final String testId;
  final String testTitle;
  final String section;
  final int score;
  final int totalMarks;
  final double accuracy;
  final DateTime attemptedAt;

  const TestScore({
    required this.testId,
    required this.testTitle,
    required this.section,
    required this.score,
    required this.totalMarks,
    required this.accuracy,
    required this.attemptedAt,
  });

  double get percentage => totalMarks > 0 ? (score / totalMarks) * 100 : 0.0;

  @override
  List<Object?> get props => [
    testId,
    testTitle,
    section,
    score,
    totalMarks,
    accuracy,
    attemptedAt,
  ];
}

/// Section-specific performance
class SectionPerformance extends Equatable {
  final String section;
  final int attempts;
  final double accuracy;
  final int avgTimeTaken;
  final List<String> strongTopics;
  final List<String> weakTopics;

  const SectionPerformance({
    required this.section,
    this.attempts = 0,
    this.accuracy = 0.0,
    this.avgTimeTaken = 0,
    this.strongTopics = const [],
    this.weakTopics = const [],
  });

  @override
  List<Object?> get props => [
    section,
    attempts,
    accuracy,
    avgTimeTaken,
    strongTopics,
    weakTopics,
  ];
}
