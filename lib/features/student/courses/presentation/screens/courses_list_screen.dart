import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/course_entity.dart';
import '../bloc/courses_bloc.dart';
import 'course_details_screen.dart';

/// Courses List Screen - Shows enrolled courses
class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentId = _resolveStudentId();
      if (studentId != null) {
        context.read<CoursesBloc>().add(
          CoursesLoadRequested(studentId: studentId),
        );
      }
    });
  }

  List<CourseEntity> _filterCourses(List<CourseEntity> courses) {
    if (_searchQuery.isEmpty) return courses;
    return courses.where((course) {
      final query = _searchQuery.toLowerCase();
      return course.title.toLowerCase().contains(query) ||
          course.description.toLowerCase().contains(query) ||
          course.sections.any((s) => s.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final studentId = _resolveStudentId();
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search courses...',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('My Courses'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<CoursesBloc, CoursesState>(
        builder: (context, state) {
          if (state.status == CoursesStatus.loading) {
            return _buildLoadingState();
          }

          if (state.status == CoursesStatus.failure) {
            return _buildErrorState(
              context,
              state.errorMessage ?? 'An error occurred',
            );
          }

          final filteredCourses = _filterCourses(state.courses);

          if (state.courses.isEmpty) {
            return _buildEmptyState(context);
          }

          if (filteredCourses.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                if (studentId == null) return;
                context.read<CoursesBloc>().add(
                  CoursesRefreshRequested(studentId: studentId),
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No results for "$_searchQuery"',
                        style: AppTextStyles.bodyLarge,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (studentId == null) return;
              context.read<CoursesBloc>().add(
                CoursesRefreshRequested(studentId: studentId),
              );
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                double childAspectRatio = 2.6;

                if (constraints.maxWidth >= 1200) {
                  crossAxisCount = 3;
                  childAspectRatio = 1.6;
                } else if (constraints.maxWidth >= 900) {
                  crossAxisCount = 2;
                  childAspectRatio = 1.8;
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 2;
                  childAspectRatio = 1.6;
                }

                if (crossAxisCount == 1) {
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      return _CourseCard(course: filteredCourses[index]);
                    },
                  );
                }

                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: filteredCourses.length,
                  itemBuilder: (context, index) {
                    return _CourseCard(course: filteredCourses[index]);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String? _resolveStudentId() {
    final authState = context.read<AuthBloc>().state;
    return authState.user?.id;
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 3,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.surface,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text('Something went wrong', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              context.read<CoursesBloc>().add(
                const CoursesLoadRequested(studentId: 'current_user'),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final studentId = _resolveStudentId();
        if (studentId == null) return;
        context.read<CoursesBloc>().add(
          CoursesRefreshRequested(studentId: studentId),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 80,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('No Courses Yet', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  'You haven\'t been enrolled in any courses. Please contact your admin.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Course Card Widget
class _CourseCard extends StatelessWidget {
  final CourseEntity course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CourseDetailsScreen(courseId: course.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        course.title.isNotEmpty
                            ? course.title[0].toUpperCase()
                            : 'C',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Course Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: AppTextStyles.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          course.description,
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Section Tags
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: course.sections.map((section) {
                  return _SectionChip(section: section);
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Stats Row
              Row(
                children: [
                  _StatItem(
                    icon: Icons.library_books_outlined,
                    label: '${course.materialCount} Materials',
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _StatItem(
                    icon: Icons.quiz_outlined,
                    label: '${course.testCount} Tests',
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String section;

  const _SectionChip({required this.section});

  Color get _chipColor {
    switch (section) {
      case 'Verbal Reasoning':
        return AppColors.primary;
      case 'Quantitative Reasoning':
        return AppColors.secondary;
      case 'Analytical Writing':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: _chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        section,
        style: AppTextStyles.labelSmall.copyWith(color: _chipColor),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}
