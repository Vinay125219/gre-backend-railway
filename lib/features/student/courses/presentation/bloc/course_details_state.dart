import 'package:equatable/equatable.dart';
import '../../domain/entities/course_entity.dart';
import '../../../tests/domain/entities/test_entity.dart';
import '../../../../admin/content/domain/entities/content_entity.dart';

enum CourseDetailsStatus { initial, loading, success, failure }

class CourseDetailsState extends Equatable {
  final CourseDetailsStatus status;
  final CourseEntity? course;
  final List<TestEntity> tests;
  final List<ContentEntity> content;
  final String? errorMessage;

  const CourseDetailsState({
    this.status = CourseDetailsStatus.initial,
    this.course,
    this.tests = const [],
    this.content = const [],
    this.errorMessage,
  });

  CourseDetailsState copyWith({
    CourseDetailsStatus? status,
    CourseEntity? course,
    List<TestEntity>? tests,
    List<ContentEntity>? content,
    String? errorMessage,
  }) {
    return CourseDetailsState(
      status: status ?? this.status,
      course: course ?? this.course,
      tests: tests ?? this.tests,
      content: content ?? this.content,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, course, tests, content, errorMessage];
}
