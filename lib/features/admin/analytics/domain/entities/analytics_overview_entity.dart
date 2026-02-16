import 'package:equatable/equatable.dart';

class AnalyticsOverviewEntity extends Equatable {
  final int totalStudents;
  final int activeStudents;
  final int testsCompleted;
  final double avgAccuracy;
  final List<double> activityData; // Last 7 days
  final List<StudentPerformanceEntity> topStudents;
  final Map<String, double> sectionPerformance; // Verbal, Quant, AWA
  final Map<String, double> performanceDistribution;

  const AnalyticsOverviewEntity({
    required this.totalStudents,
    required this.activeStudents,
    required this.testsCompleted,
    required this.avgAccuracy,
    required this.activityData,
    required this.topStudents,
    required this.sectionPerformance,
    required this.performanceDistribution,
  });

  @override
  List<Object?> get props => [
    totalStudents,
    activeStudents,
    testsCompleted,
    avgAccuracy,
    activityData,
    topStudents,
    sectionPerformance,
    performanceDistribution,
  ];
}

class StudentPerformanceEntity extends Equatable {
  final String id;
  final String name;
  final double avgScore;
  final String trend; // "+5%"

  const StudentPerformanceEntity({
    required this.id,
    required this.name,
    required this.avgScore,
    required this.trend,
  });

  @override
  List<Object?> get props => [id, name, avgScore, trend];
}
