import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_student_repository.dart';
import 'admin_students_event.dart';
import 'admin_students_state.dart';

class AdminStudentsBloc extends Bloc<AdminStudentsEvent, AdminStudentsState> {
  final AdminStudentRepository _repository;

  AdminStudentsBloc({required AdminStudentRepository repository})
    : _repository = repository,
      super(const AdminStudentsState()) {
    on<AdminStudentsLoadRequested>(_onLoadRequested);
    on<AdminStudentCreateRequested>(_onCreateRequested);
    on<AdminStudentUpdateRequested>(_onUpdateRequested);
  }

  Future<void> _onUpdateRequested(
    AdminStudentUpdateRequested event,
    Emitter<AdminStudentsState> emit,
  ) async {
    emit(state.copyWith(status: AdminStudentsStatus.loading));
    final result = await _repository.updateStudent(
      event.student,
      assignedCourses: event.assignedCourses,
      password: event.password,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminStudentsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        emit(state.copyWith(status: AdminStudentsStatus.updated));
        // Reload list to reflect changes
        add(AdminStudentsLoadRequested());
      },
    );
  }

  Future<void> _onLoadRequested(
    AdminStudentsLoadRequested event,
    Emitter<AdminStudentsState> emit,
  ) async {
    emit(state.copyWith(status: AdminStudentsStatus.loading));
    final result = await _repository.getAllStudents();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminStudentsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (students) => emit(
        state.copyWith(status: AdminStudentsStatus.success, students: students),
      ),
    );
  }

  Future<void> _onCreateRequested(
    AdminStudentCreateRequested event,
    Emitter<AdminStudentsState> emit,
  ) async {
    emit(state.copyWith(status: AdminStudentsStatus.loading));
    final result = await _repository.createStudent(
      name: event.name,
      email: event.email,
      password: event.password,
      assignedCourses: event.assignedCourses,
      expiryDate: event.expiryDate,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminStudentsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        // Emit created status first, then reload list
        emit(state.copyWith(status: AdminStudentsStatus.created));
        add(AdminStudentsLoadRequested());
      },
    );
  }
}
