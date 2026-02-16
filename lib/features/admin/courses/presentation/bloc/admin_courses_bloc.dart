import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_course_repository.dart';
import 'admin_courses_event.dart';
import 'admin_courses_state.dart';

class AdminCoursesBloc extends Bloc<AdminCoursesEvent, AdminCoursesState> {
  final AdminCourseRepository _repository;

  AdminCoursesBloc({required AdminCourseRepository repository})
    : _repository = repository,
      super(const AdminCoursesState()) {
    on<AdminCoursesLoadRequested>(_onLoadRequested);
    on<AdminCourseCreateRequested>(_onCreateRequested);
    on<AdminCourseUpdateRequested>(_onUpdateRequested);
    on<AdminCourseDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    AdminCoursesLoadRequested event,
    Emitter<AdminCoursesState> emit,
  ) async {
    emit(state.copyWith(status: AdminCoursesStatus.loading));
    final result = await _repository.getAllCourses();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminCoursesStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (courses) => emit(
        state.copyWith(status: AdminCoursesStatus.success, courses: courses),
      ),
    );
  }

  Future<void> _onCreateRequested(
    AdminCourseCreateRequested event,
    Emitter<AdminCoursesState> emit,
  ) async {
    emit(state.copyWith(status: AdminCoursesStatus.loading));

    var courseToCreate = event.course;

    // Thumbnail upload skipped in Mock Mode
    if (event.thumbnailFile != null) {
      // Mock URL if file provided
      courseToCreate = courseToCreate.copyWith(
        thumbnailUrl: 'mock_thumbnail_url',
      );
    }

    final result = await _repository.createCourse(courseToCreate);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminCoursesStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        add(AdminCoursesLoadRequested());
      },
    );
  }

  Future<void> _onUpdateRequested(
    AdminCourseUpdateRequested event,
    Emitter<AdminCoursesState> emit,
  ) async {
    emit(state.copyWith(status: AdminCoursesStatus.loading));

    var courseToUpdate = event.course;

    if (event.newThumbnailFile != null) {
      courseToUpdate = courseToUpdate.copyWith(
        thumbnailUrl: 'mock_thumbnail_url_updated',
      );
    }

    final result = await _repository.updateCourse(courseToUpdate);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminCoursesStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        add(AdminCoursesLoadRequested());
      },
    );
  }

  Future<void> _onDeleteRequested(
    AdminCourseDeleteRequested event,
    Emitter<AdminCoursesState> emit,
  ) async {
    emit(state.copyWith(status: AdminCoursesStatus.loading));

    final result = await _repository.deleteCourse(event.courseId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminCoursesStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        add(AdminCoursesLoadRequested());
      },
    );
  }
}
