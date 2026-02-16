part of 'courses_bloc.dart';

enum CoursesStatus { initial, loading, success, failure }

class CoursesState extends Equatable {
  final CoursesStatus status;
  final List<CourseEntity> courses;
  final CourseEntity? selectedCourse;
  final String? errorMessage;

  const CoursesState({
    this.status = CoursesStatus.initial,
    this.courses = const [],
    this.selectedCourse,
    this.errorMessage,
  });

  CoursesState copyWith({
    CoursesStatus? status,
    List<CourseEntity>? courses,
    CourseEntity? selectedCourse,
    String? errorMessage,
  }) {
    return CoursesState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      selectedCourse: selectedCourse ?? this.selectedCourse,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, courses, selectedCourse, errorMessage];
}
