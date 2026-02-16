part of 'test_taking_bloc.dart';

enum TestTakingStatus {
  initial,
  loading,
  inProgress,
  submitting,
  completed,
  failure,
}

class TestTakingState extends Equatable {
  final TestTakingStatus status;
  final TestEntity? test;
  final List<QuestionEntity> questions;
  final TestAttemptEntity? attempt;
  final int currentQuestionIndex;
  final int remainingSeconds;
  final Map<String, dynamic> answers;
  final Map<String, bool> markedForReview;
  final String? errorMessage;

  const TestTakingState({
    this.status = TestTakingStatus.initial,
    this.test,
    this.questions = const [],
    this.attempt,
    this.currentQuestionIndex = 0,
    this.remainingSeconds = 0,
    this.answers = const {},
    this.markedForReview = const {},
    this.errorMessage,
  });

  /// Current question
  QuestionEntity? get currentQuestion =>
      questions.isNotEmpty && currentQuestionIndex < questions.length
      ? questions[currentQuestionIndex]
      : null;

  /// Count of answered questions
  int get answeredCount => answers.length;

  /// Count of questions marked for review
  int get markedCount => markedForReview.values.where((v) => v).length;

  /// Is current question answered
  bool get isCurrentAnswered =>
      currentQuestion != null && answers.containsKey(currentQuestion!.id);

  /// Is current question marked
  bool get isCurrentMarked =>
      currentQuestion != null &&
      (markedForReview[currentQuestion!.id] ?? false);

  /// Progress percentage
  double get progress =>
      questions.isNotEmpty ? answeredCount / questions.length : 0.0;

  /// Formatted remaining time
  String get formattedTime {
    final hours = remainingSeconds ~/ 3600;
    final mins = (remainingSeconds % 3600) ~/ 60;
    final secs = remainingSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Is time running low (less than 5 minutes)
  bool get isTimeRunningLow => remainingSeconds < 300;

  TestTakingState copyWith({
    TestTakingStatus? status,
    TestEntity? test,
    List<QuestionEntity>? questions,
    TestAttemptEntity? attempt,
    int? currentQuestionIndex,
    int? remainingSeconds,
    Map<String, dynamic>? answers,
    Map<String, bool>? markedForReview,
    String? errorMessage,
  }) {
    return TestTakingState(
      status: status ?? this.status,
      test: test ?? this.test,
      questions: questions ?? this.questions,
      attempt: attempt ?? this.attempt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      answers: answers ?? this.answers,
      markedForReview: markedForReview ?? this.markedForReview,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    test,
    questions,
    attempt,
    currentQuestionIndex,
    remainingSeconds,
    answers,
    markedForReview,
    errorMessage,
  ];
}
