import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/test_entity.dart';
import '../../domain/repositories/test_repository.dart';

part 'test_taking_event.dart';
part 'test_taking_state.dart';

class TestTakingBloc extends Bloc<TestTakingEvent, TestTakingState> {
  final TestRepository testRepository;
  Timer? _timer;

  TestTakingBloc({required this.testRepository})
    : super(const TestTakingState()) {
    on<TestTakingStarted>(_onStarted);
    on<TestTakingQuestionChanged>(_onQuestionChanged);
    on<TestTakingAnswerSaved>(_onAnswerSaved);
    on<TestTakingAnswerCleared>(_onAnswerCleared);
    on<TestTakingMarkToggled>(_onMarkToggled);
    on<TestTakingTimerTicked>(_onTimerTicked);
    on<TestTakingSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    TestTakingStarted event,
    Emitter<TestTakingState> emit,
  ) async {
    emit(state.copyWith(status: TestTakingStatus.loading));

    // Get test details
    final testResult = await testRepository.getTestById(event.testId);
    if (testResult.isLeft()) {
      emit(
        state.copyWith(
          status: TestTakingStatus.failure,
          errorMessage: 'Failed to load test',
        ),
      );
      return;
    }

    final test = testResult.getOrElse(() => throw Exception());

    // Get questions
    final questionsResult = await testRepository.getQuestions(event.testId);
    if (questionsResult.isLeft()) {
      emit(
        state.copyWith(
          status: TestTakingStatus.failure,
          errorMessage: 'Failed to load questions',
        ),
      );
      return;
    }

    final questions = questionsResult.getOrElse(() => []);

    // Start attempt
    final attemptResult = await testRepository.startAttempt(
      event.testId,
      event.studentId,
    );
    if (attemptResult.isLeft()) {
      emit(
        state.copyWith(
          status: TestTakingStatus.failure,
          errorMessage: 'Failed to start test',
        ),
      );
      return;
    }

    final attempt = attemptResult.getOrElse(() => throw Exception());

    // Start timer
    final totalSeconds = test.duration * 60;
    _startTimer(totalSeconds);

    emit(
      state.copyWith(
        status: TestTakingStatus.inProgress,
        test: test,
        questions: questions,
        attempt: attempt,
        remainingSeconds: totalSeconds,
        answers: {},
        markedForReview: {},
      ),
    );
  }

  void _onQuestionChanged(
    TestTakingQuestionChanged event,
    Emitter<TestTakingState> emit,
  ) {
    if (event.questionIndex >= 0 &&
        event.questionIndex < state.questions.length) {
      emit(state.copyWith(currentQuestionIndex: event.questionIndex));
    }
  }

  Future<void> _onAnswerSaved(
    TestTakingAnswerSaved event,
    Emitter<TestTakingState> emit,
  ) async {
    final updatedAnswers = Map<String, dynamic>.from(state.answers);
    updatedAnswers[event.questionId] = event.answer;
    emit(state.copyWith(answers: updatedAnswers));

    // Save to backend
    if (state.attempt != null) {
      await testRepository.saveAnswer(
        state.attempt!.id,
        event.questionId,
        event.answer,
      );
    }
  }

  Future<void> _onAnswerCleared(
    TestTakingAnswerCleared event,
    Emitter<TestTakingState> emit,
  ) async {
    final updatedAnswers = Map<String, dynamic>.from(state.answers);
    updatedAnswers.remove(event.questionId);
    emit(state.copyWith(answers: updatedAnswers));

    // Save to backend (null answer)
    if (state.attempt != null) {
      await testRepository.saveAnswer(
        state.attempt!.id,
        event.questionId,
        null,
      );
    }
  }

  Future<void> _onMarkToggled(
    TestTakingMarkToggled event,
    Emitter<TestTakingState> emit,
  ) async {
    final updatedMarked = Map<String, bool>.from(state.markedForReview);
    updatedMarked[event.questionId] =
        !(updatedMarked[event.questionId] ?? false);
    emit(state.copyWith(markedForReview: updatedMarked));

    // Save to backend
    if (state.attempt != null) {
      await testRepository.toggleMarkForReview(
        state.attempt!.id,
        event.questionId,
        updatedMarked[event.questionId] ?? false,
      );
    }
  }

  void _onTimerTicked(
    TestTakingTimerTicked event,
    Emitter<TestTakingState> emit,
  ) {
    if (event.remainingSeconds <= 0) {
      // Auto-submit when time is up
      add(const TestTakingSubmitted());
    } else {
      emit(state.copyWith(remainingSeconds: event.remainingSeconds));
    }
  }

  Future<void> _onSubmitted(
    TestTakingSubmitted event,
    Emitter<TestTakingState> emit,
  ) async {
    _timer?.cancel();
    emit(state.copyWith(status: TestTakingStatus.submitting));

    if (state.attempt == null) {
      emit(
        state.copyWith(
          status: TestTakingStatus.failure,
          errorMessage: 'No active attempt',
        ),
      );
      return;
    }

    final result = await testRepository.submitAttempt(state.attempt!.id);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TestTakingStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (attempt) => emit(
        state.copyWith(status: TestTakingStatus.completed, attempt: attempt),
      ),
    );
  }

  void _startTimer(int totalSeconds) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = totalSeconds - timer.tick;
      add(TestTakingTimerTicked(remainingSeconds: remaining));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
