import 'package:equatable/equatable.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';

enum AdminCoursesStatus { initial, loading, success, failure }

class AdminCoursesState extends Equatable {
  final AdminCoursesStatus status;
  final List<CourseEntity> courses;
  final String? errorMessage;

  const AdminCoursesState({
    this.status = AdminCoursesStatus.initial,
    this.courses = const [],
    this.errorMessage,
  });

  AdminCoursesState copyWith({
    AdminCoursesStatus? status,
    List<CourseEntity>? courses,
    String? errorMessage,
  }) {
    return AdminCoursesState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, courses, errorMessage];
}
