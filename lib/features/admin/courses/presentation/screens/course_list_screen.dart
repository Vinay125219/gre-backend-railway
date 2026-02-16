import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';
import '../bloc/admin_courses_bloc.dart';
import '../bloc/admin_courses_event.dart';
import '../bloc/admin_courses_state.dart';

class CourseListScreen extends StatelessWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AdminCoursesBloc>()..add(AdminCoursesLoadRequested()),
      child: const _CourseListView(),
    );
  }
}

class _CourseListView extends StatelessWidget {
  const _CourseListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminCoursesBloc>().add(AdminCoursesLoadRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<AdminCoursesBloc, AdminCoursesState>(
        listener: (context, state) {
          if (state.status == AdminCoursesStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == AdminCoursesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.courses.isEmpty &&
              state.status == AdminCoursesStatus.success) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminCoursesBloc>().add(AdminCoursesLoadRequested());
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                double childAspectRatio = 0.9;

                if (constraints.maxWidth >= 1200) {
                  crossAxisCount = 4;
                  childAspectRatio = 0.85;
                } else if (constraints.maxWidth >= 900) {
                  crossAxisCount = 3;
                  childAspectRatio = 0.8;
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 2;
                  childAspectRatio = 0.8;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: state.courses.length,
                  itemBuilder: (context, index) {
                    final course = state.courses[index];
                    return _CourseCard(course: course);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.pushNamed('adminCreateCourse');
          if (context.mounted) {
            context.read<AdminCoursesBloc>().add(AdminCoursesLoadRequested());
          }
          if (context.mounted && result == 'saved') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Course saved successfully')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No courses found',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Create your first course to get started'),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseEntity course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context
              .pushNamed(
                'adminEditCourse',
                pathParameters: {'courseId': course.id},
                extra: course,
              )
              .then((result) {
                if (context.mounted && result == 'saved') {
                  context.read<AdminCoursesBloc>().add(
                    AdminCoursesLoadRequested(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course updated successfully'),
                    ),
                  );
                }
              });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Container(
                color: AppColors.surfaceVariant,
                child: course.thumbnailUrl != null
                    ? Image.network(
                        course.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(Icons.image_not_supported),
                            ),
                      )
                    : const Center(child: Icon(Icons.school, size: 40)),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.book,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.sections.length} Sections',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
