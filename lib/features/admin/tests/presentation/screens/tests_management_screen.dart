import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/route_names.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../../../courses/domain/repositories/admin_course_repository.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';
import '../../../../student/tests/domain/entities/test_entity.dart';
import '../bloc/admin_tests_bloc.dart';
import '../bloc/admin_tests_event.dart';
import '../bloc/admin_tests_state.dart';

/// Admin Tests Management Screen
class TestsManagementScreen extends StatefulWidget {
  const TestsManagementScreen({super.key});

  @override
  State<TestsManagementScreen> createState() => _TestsManagementScreenState();
}

class _TestsManagementScreenState extends State<TestsManagementScreen> {
  String _filter = 'all';
  List<CourseEntity> _courses = [];
  bool _coursesLoading = false;
  String? _coursesError;
  String _selectedCourseId = 'all';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminTestsBloc>()
        ..add(
          AdminTestsLoadRequested(
            courseId: _selectedCourseId == 'all' ? null : _selectedCourseId,
          ),
        ),
      child: BlocConsumer<AdminTestsBloc, AdminTestsState>(
        listener: (context, state) {
          if (state.status == AdminTestsStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tests Management'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<AdminTestsBloc>().add(
                      const AdminTestsLoadRequested(),
                    );
                  },
                  tooltip: 'Refresh',
                ),
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  onPressed: () => context.push(RouteNames.adminAnalytics),
                  tooltip: 'Analytics',
                ),
              ],
            ),
            body: state.status == AdminTestsStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(context, state),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final route = _selectedCourseId == 'all'
                    ? RouteNames.adminCreateTest
                    : '${RouteNames.adminCreateTest}?courseId=$_selectedCourseId';
                final result = await context.push(route);
                // Refresh list after returning from creation
                if (context.mounted) {
                  context.read<AdminTestsBloc>().add(
                    AdminTestsLoadRequested(
                      courseId: _selectedCourseId == 'all'
                          ? null
                          : _selectedCourseId,
                    ),
                  );
                }
                if (context.mounted &&
                    (result == 'created' || result == 'updated')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result == 'created'
                            ? 'Test created successfully'
                            : 'Test updated successfully',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Test'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdminTestsState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tests = _getFilteredTests(state.tests);

    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              _buildCourseFilter(),
              const SizedBox(height: AppSpacing.sm),
              screenWidth < 600
                  ? _buildMobileFilterBar(tests.length, state.tests)
                  : _buildDesktopFilterBar(tests.length, state.tests),
            ],
          ),
        ),

        // Tests List
        Expanded(
          child: tests.isEmpty
              ? _buildEmptyState(context)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 1;
                    double childAspectRatio = 2.5;

                    if (constraints.maxWidth >= 900) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.4;
                    } else if (constraints.maxWidth >= 600) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.6;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: tests.length,
                      itemBuilder: (context, index) {
                        return _buildTestCard(context, tests[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCourseFilter() {
    if (_coursesLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_courses.isEmpty) {
      final message = _coursesError ?? 'No courses available yet.';
      return Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reload'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('tests-course-$_selectedCourseId'),
      initialValue: _selectedCourseId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Course',
        prefixIcon: Icon(Icons.school_outlined),
      ),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('All courses')),
        ..._courses.map(
          (course) => DropdownMenuItem(
            value: course.id,
            child: Text(course.title, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedCourseId = value);
        context.read<AdminTestsBloc>().add(
          AdminTestsLoadRequested(courseId: value == 'all' ? null : value),
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
        if (_selectedCourseId != 'all' &&
            !courses.any((course) => course.id == _selectedCourseId)) {
          _selectedCourseId = 'all';
        }
      }),
    );
  }

  Widget _buildMobileFilterBar(int filteredCount, List<TestEntity> allTests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'published', label: Text('Published')),
              ButtonSegment(value: 'draft', label: Text('Drafts')),
            ],
            selected: {_filter},
            onSelectionChanged: (v) => setState(() => _filter = v.first),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatBadge('Showing: $filteredCount', AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            _buildStatBadge(
              'Total: ${allTests.length}',
              AppColors.textSecondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFilterBar(int filteredCount, List<TestEntity> allTests) {
    return Row(
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('All')),
            ButtonSegment(value: 'published', label: Text('Published')),
            ButtonSegment(value: 'draft', label: Text('Drafts')),
          ],
          selected: {_filter},
          onSelectionChanged: (v) => setState(() => _filter = v.first),
        ),
        const Spacer(),
        _buildStatBadge('Showing: $filteredCount', AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        _buildStatBadge('Total: ${allTests.length}', AppColors.textSecondary),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('No tests found', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: () async {
              await context.push(RouteNames.adminCreateTest);
              if (context.mounted) {
                context.read<AdminTestsBloc>().add(
                  const AdminTestsLoadRequested(),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Test'),
          ),
        ],
      ),
    );
  }

  List<TestEntity> _getFilteredTests(List<TestEntity> tests) {
    switch (_filter) {
      case 'published':
        return tests.where((t) => t.published).toList();
      case 'draft':
        return tests.where((t) => !t.published).toList();
      default:
        return tests;
    }
  }

  Widget _buildStatBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, TestEntity test) {
    final isPublished = test.published;

    return Card(
      child: InkWell(
        onTap: () => context.push(
          RouteNames.adminTestDetail.replaceFirst(':testId', test.id),
          extra: test,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      test.title,
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (v) => _handleAction(context, v, test),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'publish',
                        child: Text(isPublished ? 'Unpublish' : 'Publish'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildSectionChip(test.section),
              const Spacer(),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  _buildInfoItem(
                    Icons.quiz_outlined,
                    '${test.totalQuestions} Q',
                  ),
                  _buildInfoItem(Icons.timer_outlined, '${test.duration}m'),
                  _buildInfoItem(
                    Icons.grade_outlined,
                    '${test.totalMarks} Marks',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? AppColors.successLight
                          : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      isPublished ? 'Published' : 'Draft',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isPublished
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionChip(String section) {
    Color color;
    switch (section) {
      case 'Verbal Reasoning':
        color = AppColors.primary;
        break;
      case 'Quantitative Reasoning':
        color = AppColors.secondary;
        break;
      case 'Analytical Writing':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.info;
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
        section,
        style: AppTextStyles.labelSmall.copyWith(color: color),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  void _handleAction(BuildContext context, String action, TestEntity test) {
    switch (action) {
      case 'edit':
        context
            .push(
              '${RouteNames.adminEditTest.replaceFirst(':testId', test.id)}?courseId=${test.courseId}',
            )
            .then((result) {
              if (!context.mounted) return;
              if (result == 'updated') {
                context.read<AdminTestsBloc>().add(
                  const AdminTestsLoadRequested(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test updated successfully')),
                );
              }
            });
        break;
      case 'publish':
        context.read<AdminTestsBloc>().add(
          AdminTestPublishToggled(testId: test.id, publish: !test.published),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context, test);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, TestEntity test) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Test?'),
        content: Text('Are you sure you want to delete "${test.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              context.read<AdminTestsBloc>().add(
                AdminTestDeleteRequested(testId: test.id),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
