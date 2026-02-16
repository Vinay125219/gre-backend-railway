import 'package:equatable/equatable.dart';
import '../../../../student/tests/domain/entities/test_entity.dart';
import '../../../tests/domain/repositories/admin_test_repository.dart';

enum AdminTestsStatus { initial, loading, success, failure }

class AdminTestsState extends Equatable {
  final AdminTestsStatus status;
  final List<TestEntity> tests;
  final TestEntity? selectedTest;
  final List<QuestionEntity> questions;
  final TestStats? stats;
  final String? errorMessage;
  final String? successMessage;

  const AdminTestsState({
    this.status = AdminTestsStatus.initial,
    this.tests = const [],
    this.selectedTest,
    this.questions = const [],
    this.stats,
    this.errorMessage,
    this.successMessage,
  });

  AdminTestsState copyWith({
    AdminTestsStatus? status,
    List<TestEntity>? tests,
    TestEntity? selectedTest,
    List<QuestionEntity>? questions,
    TestStats? stats,
    String? errorMessage,
    String? successMessage,
    bool clearSelectedTest = false,
    bool clearStats = false,
    bool clearMessages = false,
  }) {
    return AdminTestsState(
      status: status ?? this.status,
      tests: tests ?? this.tests,
      selectedTest: clearSelectedTest
          ? null
          : (selectedTest ?? this.selectedTest),
      questions: questions ?? this.questions,
      stats: clearStats ? null : (stats ?? this.stats),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    tests,
    selectedTest,
    questions,
    stats,
    errorMessage,
    successMessage,
  ];

  // Computed properties
  int get totalTests => tests.length;
  int get publishedTests => tests.where((t) => t.published).length;
  int get draftTests => tests.where((t) => !t.published).length;

  List<TestEntity> get verbalTests =>
      tests.where((t) => t.section == 'verbal').toList();
  List<TestEntity> get quantTests =>
      tests.where((t) => t.section == 'quant').toList();
  List<TestEntity> get awaTests =>
      tests.where((t) => t.section == 'awa').toList();
}
