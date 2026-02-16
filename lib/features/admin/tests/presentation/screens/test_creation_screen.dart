import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../../../../student/tests/domain/entities/test_entity.dart';
import '../../../courses/domain/repositories/admin_course_repository.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';
import '../../domain/repositories/admin_test_repository.dart';
import '../bloc/admin_tests_bloc.dart';
import '../bloc/admin_tests_event.dart';
import '../bloc/admin_tests_state.dart';

/// Admin Test Creation Screen
class TestCreationScreen extends StatefulWidget {
  final String? testId;
  final String courseId;

  const TestCreationScreen({super.key, this.testId, required this.courseId});

  @override
  State<TestCreationScreen> createState() => _TestCreationScreenState();
}

class _TestCreationScreenState extends State<TestCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedSection = 'verbal';
  int _duration = 60;
  bool _shuffleQuestions = false;
  bool _showResults = true;
  bool _pendingSave = false;
  bool _isLoadingTest = false;
  String? _loadError;
  TestEntity? _existingTest;

  final List<_QuestionData> _questions = [];
  final List<_QuestionData> _originalQuestions = [];
  List<CourseEntity> _courses = [];
  bool _coursesLoading = false;
  String? _coursesError;
  String _selectedCourseId = '';

  bool get isEditing => widget.testId != null;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
    if (isEditing) {
      _loadTestForEdit();
    }
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;
    return BlocConsumer<AdminTestsBloc, AdminTestsState>(
      listener: (context, state) {
        if (!mounted) return;
        if (isEditing) return;
        if (!_pendingSave) return;

        if (state.status == AdminTestsStatus.failure) {
          setState(() => _pendingSave = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to save test'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        if (state.status == AdminTestsStatus.success &&
            state.successMessage != null) {
          setState(() => _pendingSave = false);
          Navigator.pop(context, isEditing ? 'updated' : 'created');
        }
      },
      builder: (context, state) {
        final isSaving = isEditing
            ? _pendingSave
            : (_pendingSave && state.status == AdminTestsStatus.loading);

        if (isEditing && _isLoadingTest) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Test')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (isEditing && _loadError != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Test')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _loadError!,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _loadTestForEdit,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Text(isEditing ? 'Edit Test' : 'Create New Test'),
                actions: [
                  if (_questions.isNotEmpty)
                    isCompact
                        ? IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: isSaving ? null : _previewTest,
                            tooltip: 'Preview',
                          )
                        : TextButton.icon(
                            onPressed: isSaving ? null : _previewTest,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Preview'),
                          ),
                  const SizedBox(width: AppSpacing.sm),
                  isCompact
                      ? IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: isSaving ? null : _saveTest,
                          tooltip: 'Save',
                        )
                      : ElevatedButton.icon(
                          onPressed: isSaving ? null : _saveTest,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                  const SizedBox(width: AppSpacing.md),
                ],
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel - Test Details
                        Container(
                          width: 320,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              right: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Form(
                              key: _formKey,
                              child: _buildFormContent(),
                            ),
                          ),
                        ),

                        // Right Panel - Questions
                        Expanded(child: _buildQuestionsPanel()),
                      ],
                    );
                  } else {
                    // Mobile/Tablet Layout
                    return DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            color: AppColors.surface,
                            child: const TabBar(
                              tabs: [
                                Tab(text: 'Details'),
                                Tab(text: 'Questions'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Details Tab
                                KeepAliveWrapper(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: _buildFormContent(),
                                    ),
                                  ),
                                ),
                                // Questions Tab
                                _buildQuestionsPanel(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            if (isSaving)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCourseSelector(),
        const SizedBox(height: AppSpacing.lg),
        Text('Test Details', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        // Title
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Test Title *',
            hintText: 'e.g., GRE Verbal Practice Test 1',
          ),
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        const SizedBox(height: AppSpacing.md),

        // Description
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Brief description of the test',
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Section
        DropdownButtonFormField<String>(
          initialValue: _selectedSection,
          decoration: const InputDecoration(labelText: 'Section *'),
          items: const [
            DropdownMenuItem(value: 'verbal', child: Text('Verbal Reasoning')),
            DropdownMenuItem(
              value: 'quant',
              child: Text('Quantitative Reasoning'),
            ),
            DropdownMenuItem(value: 'awa', child: Text('Analytical Writing')),
          ],
          onChanged: (v) => setState(() => _selectedSection = v!),
        ),
        const SizedBox(height: AppSpacing.md),

        // Duration
        Row(
          children: [
            Expanded(
              child: Text(
                'Duration: $_duration min',
                style: AppTextStyles.bodyMedium,
              ),
            ),
            Slider(
              value: _duration.toDouble(),
              min: 15,
              max: 180,
              divisions: 33,
              label: '$_duration min',
              onChanged: (v) => setState(() => _duration = v.toInt()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Options
        SwitchListTile(
          title: const Text('Shuffle Questions'),
          value: _shuffleQuestions,
          onChanged: (v) => setState(() => _shuffleQuestions = v),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Show Results After Submit'),
          value: _showResults,
          onChanged: (v) => setState(() => _showResults = v),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(height: AppSpacing.xl),

        // Stats
        Text('Test Statistics', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        _buildStatRow('Questions', '${_questions.length}'),
        _buildStatRow('Total Marks', '${_getTotalMarks()}'),
        _buildStatRow('MCQ', '${_countByType('mcq')}'),
        _buildStatRow('MSQ', '${_countByType('msq')}'),
        _buildStatRow('NAT', '${_countByType('nat')}'),
      ],
    );
  }

  Widget _buildCourseSelector() {
    if (_coursesLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Course', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(),
        ],
      );
    }

    if (_courses.isEmpty) {
      final message = _coursesError == null
          ? 'No courses found. Create a course first.'
          : _coursesError!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Course', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload Courses'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('test-course-$_selectedCourseId'),
      initialValue: _selectedCourseId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Course'),
      items: _courses
          .map(
            (course) => DropdownMenuItem(
              value: course.id,
              child: Text(course.title, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedCourseId = value);
      },
    );
  }

  Widget _buildQuestionsPanel() {
    return Column(
      children: [
        // Questions Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: _buildQuestionsHeaderContent(),
        ),

        // Questions List
        Expanded(
          child: _questions.isEmpty
              ? _buildEmptyState()
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _questions.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _questions.removeAt(oldIndex);
                      _questions.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildQuestionCard(index, _questions[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuestionsHeaderContent() {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Row(
      children: [
        Text('Questions', style: AppTextStyles.titleMedium),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            '${_questions.length}',
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
          ),
        ),
        const Spacer(),
        if (isSmall) ...[
          IconButton(
            onPressed: () => _showImportDialog(),
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import',
          ),
          IconButton(
            onPressed: () => _showAddQuestionDialog(),
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            tooltip: 'Add Question',
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: () => _showImportDialog(),
            icon: const Icon(Icons.upload_file),
            label: const Text('Import'),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: () => _showAddQuestionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Question'),
          ),
        ],
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('No questions added yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add questions manually or import from a file',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showImportDialog(),
                icon: const Icon(Icons.upload_file),
                label: const Text('Import Questions'),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () => _showAddQuestionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, _QuestionData question) {
    return Card(
      key: ValueKey(question.id),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: Text(
          question.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            _buildTypeChip(question.type),
            const SizedBox(width: AppSpacing.sm),
            Text('${question.marks} marks'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditQuestionDialog(index, question),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: () => _deleteQuestion(index),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    String label;

    switch (type) {
      case 'mcq':
        color = AppColors.primary;
        label = 'MCQ';
        break;
      case 'msq':
        color = AppColors.secondary;
        label = 'MSQ';
        break;
      case 'nat':
        color = AppColors.warning;
        label = 'NAT';
        break;
      default:
        color = AppColors.info;
        label = type.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }

  int _getTotalMarks() {
    return _questions.fold(0, (sum, q) => sum + q.marks);
  }

  int _countByType(String type) {
    return _questions.where((q) => q.type == type).length;
  }

  void _showAddQuestionDialog() {
    _showQuestionDialog(null, null);
  }

  void _showEditQuestionDialog(int index, _QuestionData question) {
    _showQuestionDialog(index, question);
  }

  void _showQuestionDialog(int? index, _QuestionData? question) {
    final isEdit = question != null;
    final questionController = TextEditingController(
      text: question?.question ?? '',
    );
    String type = question?.type ?? 'mcq';
    int marks = question?.marks ?? 1;
    final options = List<String>.from(question?.options ?? []);
    while (options.length < 4) {
      options.add('');
    }
    int correctOption = question?.correctOption ?? 0;
    if (correctOption >= options.length) {
      correctOption = 0;
    }
    final natAnswerController = TextEditingController(
      text: question?.natAnswer ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Question' : 'Add Question'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width > 600
                ? 600
                : MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Type
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'mcq', label: Text('MCQ')),
                      ButtonSegment(value: 'msq', label: Text('MSQ')),
                      ButtonSegment(value: 'nat', label: Text('NAT')),
                    ],
                    selected: {type},
                    onSelectionChanged: (v) =>
                        setDialogState(() => type = v.first),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Question Text
                  TextField(
                    controller: questionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Question *',
                      hintText: 'Enter question text',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Marks
                  Row(
                    children: [
                      const Text('Marks: '),
                      DropdownButton<int>(
                        value: marks,
                        items: [1, 2, 3, 4, 5]
                            .map(
                              (m) =>
                                  DropdownMenuItem(value: m, child: Text('$m')),
                            )
                            .toList(),
                        onChanged: (v) => setDialogState(() => marks = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Options (for MCQ/MSQ)
                  if (type != 'nat') ...[
                    const Text('Options:'),
                    const SizedBox(height: AppSpacing.sm),
                    ...List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            // ignore: deprecated_member_use
                            Radio<int>(
                              value: i,
                              // ignore: deprecated_member_use
                              groupValue: correctOption,
                              // ignore: deprecated_member_use
                              onChanged: (v) =>
                                  setDialogState(() => correctOption = v!),
                            ),
                            Expanded(
                              child: TextField(
                                onChanged: (v) => options[i] = v,
                                decoration: InputDecoration(
                                  hintText:
                                      'Option ${String.fromCharCode(65 + i)}',
                                  isDense: true,
                                ),
                                controller: TextEditingController(
                                  text: options[i],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // NAT Answer
                  if (type == 'nat')
                    TextField(
                      controller: natAnswerController,
                      decoration: const InputDecoration(
                        labelText: 'Correct Answer (Numeric)',
                        hintText: 'Enter the correct numeric answer',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final id =
                    question?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString();
                final newQuestion = _QuestionData(
                  id,
                  questionController.text,
                  type,
                  marks,
                  options.where((o) => o.isNotEmpty).toList(),
                  correctOption,
                  natAnswer: type == 'nat'
                      ? natAnswerController.text.trim()
                      : null,
                );

                setState(() {
                  if (index != null) {
                    _questions[index] = newQuestion;
                  } else {
                    _questions.add(newQuestion);
                  }
                });

                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              setState(() => _questions.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Questions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Import questions from CSV or JSON file'),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV import coming soon')),
                    );
                  },
                  icon: const Icon(Icons.table_chart),
                  label: const Text('CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('JSON import coming soon')),
                    );
                  },
                  icon: const Icon(Icons.code),
                  label: const Text('JSON'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _previewTest() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preview mode coming soon')));
  }

  void _saveTest() {
    if (_pendingSave) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourseId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a course')));
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }
    setState(() => _pendingSave = true);

    if (isEditing) {
      _updateTestWithQuestions();
      return;
    }

    final questions = _buildQuestionEntities(testId: '');
    context.read<AdminTestsBloc>().add(
      AdminTestCreateRequested(
        courseId: _selectedCourseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        section: _selectedSection,
        duration: _duration,
        shuffleQuestions: _shuffleQuestions,
        showResults: _showResults,
        questions: questions,
      ),
    );
  }

  Future<void> _loadTestForEdit() async {
    if (!isEditing) return;
    setState(() {
      _isLoadingTest = true;
      _loadError = null;
    });

    final repo = sl<AdminTestRepository>();
    final testId = widget.testId!;
    final testResult = await repo.getTestById(testId);
    if (!mounted) return;

    await testResult.fold(
      (failure) async {
        setState(() {
          _isLoadingTest = false;
          _loadError = failure.message;
        });
      },
      (test) async {
        _existingTest = test;
        _selectedCourseId = test.courseId;
        _titleController.text = test.title;
        _descriptionController.text = test.description;
        _selectedSection = test.section;
        _duration = test.duration;
        _shuffleQuestions = test.shuffleQuestions;
        final questionsResult = await repo.getQuestions(test.id);
        if (!mounted) return;
        questionsResult.fold(
          (failure) {
            setState(() {
              _isLoadingTest = false;
              _loadError = failure.message;
            });
          },
          (questions) {
            final mapped = questions
                .map(_questionDataFromEntity)
                .toList(growable: false);
            setState(() {
              _questions
                ..clear()
                ..addAll(mapped);
              _originalQuestions
                ..clear()
                ..addAll(mapped);
              _isLoadingTest = false;
            });
          },
        );
      },
    );
  }

  Future<void> _loadCourses() async {
    setState(() {
      _coursesLoading = true;
      _coursesError = null;
    });

    final repo = sl<AdminCourseRepository>();
    final result = await repo.getAllCourses();
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _coursesLoading = false;
        _coursesError = failure.message;
        _courses = [];
      }),
      (courses) => setState(() {
        _coursesLoading = false;
        _coursesError = null;
        _courses = courses;
        if (courses.isNotEmpty &&
            (_selectedCourseId.isEmpty ||
                !courses.any((course) => course.id == _selectedCourseId))) {
          _selectedCourseId = courses.first.id;
        }
      }),
    );
  }

  Future<void> _updateTestWithQuestions() async {
    final repo = sl<AdminTestRepository>();
    final testId = widget.testId!;
    final updatedTest = TestEntity(
      id: testId,
      courseId: _selectedCourseId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      section: _selectedSection,
      duration: _duration,
      totalQuestions: _questions.length,
      totalMarks: _getTotalMarks(),
      published: _existingTest?.published ?? false,
      shuffleQuestions: _shuffleQuestions,
      availableFrom: _existingTest?.availableFrom,
      availableUntil: _existingTest?.availableUntil,
      createdAt: _existingTest?.createdAt ?? DateTime.now(),
    );

    final updateResult = await repo.updateTest(updatedTest);
    if (!mounted) return;
    final updateFailure = updateResult.fold<String?>(
      (failure) => failure.message,
      (_) => null,
    );
    if (updateFailure != null) {
      setState(() => _pendingSave = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updateFailure),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final questionError = await _syncQuestions(repo, testId);
    if (!mounted) return;
    if (questionError != null) {
      setState(() => _pendingSave = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(questionError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _pendingSave = false);
    Navigator.pop(context, 'updated');
  }

  Future<String?> _syncQuestions(
    AdminTestRepository repo,
    String testId,
  ) async {
    final originalById = {for (final q in _originalQuestions) q.id: q};

    // Add new questions (update temp ids with server ids)
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (originalById.containsKey(question.id)) continue;
      final entity = _toQuestionEntity(question, i, testId);
      final addResult = await repo.addQuestion(
        testId: testId,
        question: entity,
      );
      final error = addResult.fold<String?>((failure) => failure.message, (
        created,
      ) {
        _questions[i] = question.copyWith(id: created.id);
        return null;
      });
      if (error != null) return error;
    }

    final currentById = {for (final q in _questions) q.id: q};

    // Update modified questions
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final original = originalById[question.id];
      if (original == null) continue;
      if (_questionEquals(question, original)) continue;
      final entity = _toQuestionEntity(question, i, testId);
      final updateResult = await repo.updateQuestion(entity);
      final error = updateResult.fold<String?>(
        (failure) => failure.message,
        (_) => null,
      );
      if (error != null) return error;
    }

    // Delete removed questions
    for (final original in _originalQuestions) {
      if (currentById.containsKey(original.id)) continue;
      final deleteResult = await repo.deleteQuestion(testId, original.id);
      final error = deleteResult.fold<String?>(
        (failure) => failure.message,
        (_) => null,
      );
      if (error != null) return error;
    }

    final currentIds = _questions.map((q) => q.id).toList();
    final originalIds = _originalQuestions.map((q) => q.id).toList();
    if (currentIds.length != originalIds.length ||
        !_listEquals(currentIds, originalIds)) {
      final reorderResult = await repo.reorderQuestions(testId, currentIds);
      final error = reorderResult.fold<String?>(
        (failure) => failure.message,
        (_) => null,
      );
      if (error != null) return error;
    }

    return null;
  }

  List<QuestionEntity> _buildQuestionEntities({required String testId}) {
    return _questions.asMap().entries.map((entry) {
      final index = entry.key;
      final q = entry.value;
      return _toQuestionEntity(q, index, testId);
    }).toList();
  }

  QuestionEntity _toQuestionEntity(_QuestionData q, int index, String testId) {
    QuestionType type;
    switch (q.type) {
      case 'msq':
        type = QuestionType.msq;
        break;
      case 'nat':
        type = QuestionType.nat;
        break;
      default:
        type = QuestionType.mcq;
    }

    final correctAnswer = q.type == 'nat'
        ? (q.natAnswer ?? '')
        : q.options.isNotEmpty
        ? q.options[q.correctOption.clamp(0, q.options.length - 1)]
        : '';

    return QuestionEntity(
      id: q.id,
      testId: testId,
      orderIndex: index,
      type: type,
      question: q.question,
      options: q.options,
      correctAnswer: correctAnswer,
      marks: q.marks,
    );
  }

  _QuestionData _questionDataFromEntity(QuestionEntity question) {
    final type = question.type == QuestionType.msq
        ? 'msq'
        : question.type == QuestionType.nat
        ? 'nat'
        : 'mcq';
    final options = List<String>.from(question.options);
    while (options.length < 4) {
      options.add('');
    }

    int correctOption = 0;
    String? natAnswer;
    if (type == 'nat') {
      natAnswer = question.correctAnswer?.toString() ?? '';
    } else {
      final answer = question.correctAnswer;
      if (answer is String) {
        correctOption = options.indexOf(answer);
      } else if (answer is List && answer.isNotEmpty) {
        final first = answer.first.toString();
        correctOption = options.indexOf(first);
      }
      if (correctOption < 0) correctOption = 0;
    }

    return _QuestionData(
      question.id,
      question.question,
      type,
      question.marks,
      options,
      correctOption,
      natAnswer: natAnswer,
    );
  }

  bool _questionEquals(_QuestionData a, _QuestionData b) {
    return a.question == b.question &&
        a.type == b.type &&
        a.marks == b.marks &&
        a.correctOption == b.correctOption &&
        a.natAnswer == b.natAnswer &&
        _listEquals(a.options, b.options);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _QuestionData {
  final String id;
  final String question;
  final String type;
  final int marks;
  final List<String> options;
  final int correctOption;
  final String? natAnswer;

  _QuestionData(
    this.id,
    this.question,
    this.type,
    this.marks,
    this.options,
    this.correctOption, {
    this.natAnswer,
  });

  _QuestionData copyWith({
    String? id,
    String? question,
    String? type,
    int? marks,
    List<String>? options,
    int? correctOption,
    String? natAnswer,
  }) {
    return _QuestionData(
      id ?? this.id,
      question ?? this.question,
      type ?? this.type,
      marks ?? this.marks,
      options ?? this.options,
      correctOption ?? this.correctOption,
      natAnswer: natAnswer ?? this.natAnswer,
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
