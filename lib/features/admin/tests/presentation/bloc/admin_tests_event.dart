import 'package:equatable/equatable.dart';
import '../../../../student/tests/domain/entities/test_entity.dart';

abstract class AdminTestsEvent extends Equatable {
  const AdminTestsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all tests
class AdminTestsLoadRequested extends AdminTestsEvent {
  final String? courseId;

  const AdminTestsLoadRequested({this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Create a new test
class AdminTestCreateRequested extends AdminTestsEvent {
  final String courseId;
  final String title;
  final String description;
  final String section;
  final int duration;
  final bool shuffleQuestions;
  final bool showResults;
  final List<QuestionEntity> questions;

  const AdminTestCreateRequested({
    required this.courseId,
    required this.title,
    required this.description,
    required this.section,
    required this.duration,
    required this.shuffleQuestions,
    required this.showResults,
    required this.questions,
  });

  @override
  List<Object?> get props => [
    courseId,
    title,
    description,
    section,
    duration,
    shuffleQuestions,
    showResults,
    questions,
  ];
}

/// Update an existing test
class AdminTestUpdateRequested extends AdminTestsEvent {
  final TestEntity test;

  const AdminTestUpdateRequested({required this.test});

  @override
  List<Object?> get props => [test];
}

/// Delete a test
class AdminTestDeleteRequested extends AdminTestsEvent {
  final String testId;

  const AdminTestDeleteRequested({required this.testId});

  @override
  List<Object?> get props => [testId];
}

/// Publish or unpublish a test
class AdminTestPublishToggled extends AdminTestsEvent {
  final String testId;
  final bool publish;

  const AdminTestPublishToggled({required this.testId, required this.publish});

  @override
  List<Object?> get props => [testId, publish];
}

/// Load questions for a test
class AdminTestQuestionsLoadRequested extends AdminTestsEvent {
  final String testId;

  const AdminTestQuestionsLoadRequested({required this.testId});

  @override
  List<Object?> get props => [testId];
}

/// Add a question to a test
class AdminTestQuestionAdded extends AdminTestsEvent {
  final String testId;
  final QuestionEntity question;

  const AdminTestQuestionAdded({required this.testId, required this.question});

  @override
  List<Object?> get props => [testId, question];
}

/// Update a question
class AdminTestQuestionUpdated extends AdminTestsEvent {
  final QuestionEntity question;

  const AdminTestQuestionUpdated({required this.question});

  @override
  List<Object?> get props => [question];
}

/// Delete a question
class AdminTestQuestionDeleted extends AdminTestsEvent {
  final String testId;
  final String questionId;

  const AdminTestQuestionDeleted({
    required this.testId,
    required this.questionId,
  });

  @override
  List<Object?> get props => [testId, questionId];
}

/// Reorder questions
class AdminTestQuestionsReordered extends AdminTestsEvent {
  final String testId;
  final List<String> questionIds;

  const AdminTestQuestionsReordered({
    required this.testId,
    required this.questionIds,
  });

  @override
  List<Object?> get props => [testId, questionIds];
}

/// Load test statistics
class AdminTestStatsLoadRequested extends AdminTestsEvent {
  final String testId;

  const AdminTestStatsLoadRequested({required this.testId});

  @override
  List<Object?> get props => [testId];
}
