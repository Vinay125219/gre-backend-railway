part of 'courses_bloc.dart';

abstract class CoursesEvent extends Equatable {
  const CoursesEvent();

  @override
  List<Object?> get props => [];
}

/// Load enrolled courses for current user
class CoursesLoadRequested extends CoursesEvent {
  final String studentId;

  const CoursesLoadRequested({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

/// Refresh courses
class CoursesRefreshRequested extends CoursesEvent {
  final String studentId;

  const CoursesRefreshRequested({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

/// Select a course to view details
class CourseSelected extends CoursesEvent {
  final String courseId;

  const CourseSelected({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}
