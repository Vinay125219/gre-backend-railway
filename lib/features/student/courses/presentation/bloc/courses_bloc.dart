import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';

part 'courses_event.dart';
part 'courses_state.dart';

class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  final CourseRepository courseRepository;

  CoursesBloc({required this.courseRepository}) : super(const CoursesState()) {
    on<CoursesLoadRequested>(_onLoadRequested);
    on<CoursesRefreshRequested>(_onRefreshRequested);
    on<CourseSelected>(_onCourseSelected);
  }

  Future<void> _onLoadRequested(
    CoursesLoadRequested event,
    Emitter<CoursesState> emit,
  ) async {
    emit(state.copyWith(status: CoursesStatus.loading));

    final result = await courseRepository.getEnrolledCourses(event.studentId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CoursesStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (courses) =>
          emit(state.copyWith(status: CoursesStatus.success, courses: courses)),
    );
  }

  Future<void> _onRefreshRequested(
    CoursesRefreshRequested event,
    Emitter<CoursesState> emit,
  ) async {
    final result = await courseRepository.getEnrolledCourses(event.studentId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CoursesStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (courses) =>
          emit(state.copyWith(status: CoursesStatus.success, courses: courses)),
    );
  }

  Future<void> _onCourseSelected(
    CourseSelected event,
    Emitter<CoursesState> emit,
  ) async {
    final result = await courseRepository.getCourseById(event.courseId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (course) => emit(state.copyWith(selectedCourse: course)),
    );
  }
}
