import 'package:equatable/equatable.dart';

/// Course entity for domain layer
class CourseEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final List<String> sections; // GRE sections: Verbal, Quant, AWA
  final bool published;
  final int materialCount;
  final int testCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CourseEntity({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.sections,
    required this.published,
    this.materialCount = 0,
    this.testCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    thumbnailUrl,
    sections,
    published,
    materialCount,
    testCount,
    createdAt,
    updatedAt,
  ];

  CourseEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    List<String>? sections,
    bool? published,
    int? materialCount,
    int? testCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sections: sections ?? this.sections,
      published: published ?? this.published,
      materialCount: materialCount ?? this.materialCount,
      testCount: testCount ?? this.testCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Enrollment entity representing student-course relationship
class EnrollmentEntity extends Equatable {
  final String id;
  final String studentId;
  final String courseId;
  final DateTime enrolledAt;
  final double progress; // 0.0 to 1.0
  final int completedMaterials;
  final int completedTests;

  const EnrollmentEntity({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.enrolledAt,
    this.progress = 0.0,
    this.completedMaterials = 0,
    this.completedTests = 0,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    courseId,
    enrolledAt,
    progress,
    completedMaterials,
    completedTests,
  ];
}
