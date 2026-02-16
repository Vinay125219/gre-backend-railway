import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_test_repository.dart';
import 'admin_tests_event.dart';
import 'admin_tests_state.dart';

class AdminTestsBloc extends Bloc<AdminTestsEvent, AdminTestsState> {
  final AdminTestRepository _repository;

  AdminTestsBloc({required AdminTestRepository repository})
    : _repository = repository,
      super(const AdminTestsState()) {
    on<AdminTestsLoadRequested>(_onLoadRequested);
    on<AdminTestCreateRequested>(_onCreateRequested);
    on<AdminTestUpdateRequested>(_onUpdateRequested);
    on<AdminTestDeleteRequested>(_onDeleteRequested);
    on<AdminTestPublishToggled>(_onPublishToggled);
    on<AdminTestQuestionsLoadRequested>(_onQuestionsLoadRequested);
    on<AdminTestQuestionAdded>(_onQuestionAdded);
    on<AdminTestQuestionUpdated>(_onQuestionUpdated);
    on<AdminTestQuestionDeleted>(_onQuestionDeleted);
    on<AdminTestQuestionsReordered>(_onQuestionsReordered);
    on<AdminTestStatsLoadRequested>(_onStatsLoadRequested);
  }

  Future<void> _onLoadRequested(
    AdminTestsLoadRequested event,
    Emitter<AdminTestsState> emit,
  ) async {
    emit(state.copyWith(status: AdminTestsStatus.loading, clearMessages: true));

    final result = await _repository.getAllTests(courseId: event.courseId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (tests) =>
          emit(state.copyWith(status: AdminTestsStatus.success, tests: tests)),
    );
  }

  Future<void> _onCreateRequested(
    AdminTestCreateRequested event,
    Emitter<AdminTestsState> emit,
  ) async {
    emit(state.copyWith(status: AdminTestsStatus.loading, clearMessages: true));

    final result = await _repository.createTest(
      courseId: event.courseId,
      title: event.title,
      description: event.description,
      section: event.section,
      duration: event.duration,
      shuffleQuestions: event.shuffleQuestions,
      showResults: event.showResults,
      questions: event.questions,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (test) {
        emit(
          state.copyWith(
            status: AdminTestsStatus.success,
            successMessage: 'Test created successfully',
          ),
        );
        // Reload tests
        add(const AdminTestsLoadRequested());
      },
    );
  }

  Future<void> _onUpdateRequested(
    AdminTestUpdateRequested event,
    Emitter<AdminTestsState> emit,
  ) async {
    emit(state.copyWith(status: AdminTestsStatus.loading, clearMessages: true));

    final result = await _repository.updateTest(event.test);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            status: AdminTestsStatus.success,
            successMessage: 'Test updated successfully',
          ),
        );
        add(const AdminTestsLoadRequested());
      },
    );
  }

  Future<void> _onDeleteRequested(
    AdminTestDeleteRequested event,
    Emitter<AdminTestsState> emit,
  ) async {
    emit(state.copyWith(status: AdminTestsStatus.loading, clearMessages: true));

    final result = await _repository.deleteTest(event.testId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            status: AdminTestsStatus.success,
            successMessage: 'Test deleted successfully',
          ),
        );
        add(const AdminTestsLoadRequested());
      },
    );
  }

  Future<void> _onPublishToggled(
    AdminTestPublishToggled event,
    Emitter<AdminTestsState> emit,
  ) async {
    emit(state.copyWith(status: AdminTestsStatus.loading, clearMessages: true));

    final result = await _repository.setTestPublished(
      event.testId,
      event.publish,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        final action = event.publish ? 'published' : 'unpublished';
        emit(
          state.copyWith(
            status: AdminTestsStatus.success,
            successMessage: 'Test $action successfully',
          ),
        );
        add(const AdminTestsLoadRequested());
      },
    );
  }

  Future<void> _onQuestionsLoadRequested(
    AdminTestQuestionsLoadRequested event,
    Emitter<AdminTestsState> emit,
  ) async {
    emit(state.copyWith(status: AdminTestsStatus.loading, clearMessages: true));

    final result = await _repository.getQuestions(event.testId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (questions) => emit(
        state.copyWith(status: AdminTestsStatus.success, questions: questions),
      ),
    );
  }

  Future<void> _onQuestionAdded(
    AdminTestQuestionAdded event,
    Emitter<AdminTestsState> emit,
  ) async {
    emit(state.copyWith(status: AdminTestsStatus.loading, clearMessages: true));

    final result = await _repository.addQuestion(
      testId: event.testId,
      question: event.question,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (question) {
        emit(
          state.copyWith(
            status: AdminTestsStatus.success,
            successMessage: 'Question added successfully',
          ),
        );
        add(AdminTestQuestionsLoadRequested(testId: event.testId));
      },
    );
  }

  Future<void> _onQuestionUpdated(
    AdminTestQuestionUpdated event,
    Emitter<AdminTestsState> emit,
  ) async {
    emit(state.copyWith(status: AdminTestsStatus.loading, clearMessages: true));

    final result = await _repository.updateQuestion(event.question);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            status: AdminTestsStatus.success,
            successMessage: 'Question updated successfully',
          ),
        );
        add(AdminTestQuestionsLoadRequested(testId: event.question.testId));
      },
    );
  }

  Future<void> _onQuestionDeleted(
    AdminTestQuestionDeleted event,
    Emitter<AdminTestsState> emit,
  ) async {
    emit(state.copyWith(status: AdminTestsStatus.loading, clearMessages: true));

    final result = await _repository.deleteQuestion(
      event.testId,
      event.questionId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            status: AdminTestsStatus.success,
            successMessage: 'Question deleted successfully',
          ),
        );
        add(AdminTestQuestionsLoadRequested(testId: event.testId));
      },
    );
  }

  Future<void> _onQuestionsReordered(
    AdminTestQuestionsReordered event,
    Emitter<AdminTestsState> emit,
  ) async {
    // Optimistically update UI
    final reorderedQuestions = <dynamic>[];
    for (final id in event.questionIds) {
      final q = state.questions.firstWhere((q) => q.id == id);
      reorderedQuestions.add(q);
    }

    final result = await _repository.reorderQuestions(
      event.testId,
      event.questionIds,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminTestsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        // Reload to get updated order indices
        add(AdminTestQuestionsLoadRequested(testId: event.testId));
      },
    );
  }

  Future<void> _onStatsLoadRequested(
    AdminTestStatsLoadRequested event,
    Emitter<AdminTestsState> emit,
  ) async {
    final result = await _repository.getTestStats(event.testId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (stats) => emit(state.copyWith(stats: stats)),
    );
  }
}
