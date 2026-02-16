part of 'test_taking_bloc.dart';

abstract class TestTakingEvent extends Equatable {
  const TestTakingEvent();

  @override
  List<Object?> get props => [];
}

/// Start a test attempt
class TestTakingStarted extends TestTakingEvent {
  final String testId;
  final String studentId;

  const TestTakingStarted({required this.testId, required this.studentId});

  @override
  List<Object?> get props => [testId, studentId];
}

/// Navigate to a specific question
class TestTakingQuestionChanged extends TestTakingEvent {
  final int questionIndex;

  const TestTakingQuestionChanged({required this.questionIndex});

  @override
  List<Object?> get props => [questionIndex];
}

/// Answer a question
class TestTakingAnswerSaved extends TestTakingEvent {
  final String questionId;
  final dynamic answer;

  const TestTakingAnswerSaved({required this.questionId, required this.answer});

  @override
  List<Object?> get props => [questionId, answer];
}

/// Toggle mark for review
class TestTakingMarkToggled extends TestTakingEvent {
  final String questionId;

  const TestTakingMarkToggled({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}

/// Timer tick
class TestTakingTimerTicked extends TestTakingEvent {
  final int remainingSeconds;

  const TestTakingTimerTicked({required this.remainingSeconds});

  @override
  List<Object?> get props => [remainingSeconds];
}

/// Submit test
class TestTakingSubmitted extends TestTakingEvent {
  const TestTakingSubmitted();
}

/// Clear current selection
class TestTakingAnswerCleared extends TestTakingEvent {
  final String questionId;

  const TestTakingAnswerCleared({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}
