import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_content_repository.dart';
import 'admin_content_event.dart';
import 'admin_content_state.dart';

class AdminContentBloc extends Bloc<AdminContentEvent, AdminContentState> {
  final AdminContentRepository _repository;

  AdminContentBloc({required AdminContentRepository repository})
    : _repository = repository,
      super(const AdminContentState()) {
    on<AdminContentLoadRequested>(_onLoadRequested);
    on<AdminContentUploadRequested>(_onUploadRequested);
    on<AdminContentNoteCreated>(_onNoteCreated);
    on<AdminContentDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    AdminContentLoadRequested event,
    Emitter<AdminContentState> emit,
  ) async {
    final courseId = event.courseId ?? 'all';
    emit(
      state.copyWith(
        status: AdminContentStatus.loading,
        activeCourseId: courseId,
        clearErrorMessage: true,
      ),
    );

    final result = (courseId == 'all')
        ? await _repository.getAllContent()
        : await _repository.getContentForCourse(courseId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminContentStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (content) => emit(
        state.copyWith(
          status: AdminContentStatus.success,
          content: content,
          clearErrorMessage: true,
        ),
      ),
    );
  }

  Future<void> _onUploadRequested(
    AdminContentUploadRequested event,
    Emitter<AdminContentState> emit,
  ) async {
    emit(state.copyWith(status: AdminContentStatus.loading));
    final result = await _repository.uploadContent(
      file: event.file,
      courseId: event.courseId,
      title: event.title,
      type: event.type,
      section: event.section,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminContentStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        // Reload content after successful upload
        add(AdminContentLoadRequested(courseId: state.activeCourseId));
      },
    );
  }

  Future<void> _onNoteCreated(
    AdminContentNoteCreated event,
    Emitter<AdminContentState> emit,
  ) async {
    emit(state.copyWith(status: AdminContentStatus.loading));
    final result = await _repository.createNote(
      courseId: event.courseId,
      title: event.title,
      content: event.content,
      section: event.section,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminContentStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        add(AdminContentLoadRequested(courseId: state.activeCourseId));
      },
    );
  }

  Future<void> _onDeleteRequested(
    AdminContentDeleteRequested event,
    Emitter<AdminContentState> emit,
  ) async {
    emit(state.copyWith(status: AdminContentStatus.loading));
    final result = await _repository.deleteContent(event.content);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminContentStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        add(AdminContentLoadRequested(courseId: state.activeCourseId));
      },
    );
  }
}
