import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/constants/route_names.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/bloc/courses_bloc.dart';
import '../../../performance/presentation/bloc/performance_bloc.dart';
import '../../../tests/domain/repositories/test_repository.dart';
import '../../../tests/domain/entities/test_entity.dart';

/// Student Dashboard Screen
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;
  List<TestEntity> _upcomingTests = [];
  bool _loadingTests = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState.user != null) {
      context.read<CoursesBloc>().add(
        CoursesLoadRequested(studentId: authState.user!.id),
      );
      context.read<PerformanceBloc>().add(
        PerformanceLoadRequested(studentId: authState.user!.id),
      );
      _loadUpcomingTests(authState.user!.id);
    }
  }

  Future<void> _loadUpcomingTests(String studentId) async {
    setState(() => _loadingTests = true);
    try {
      final result = await sl<TestRepository>().getAvailableTests(studentId);
      result.fold(
        (failure) => setState(() {
          _upcomingTests = [];
          _loadingTests = false;
        }),
        (tests) => setState(() {
          _upcomingTests = tests.take(3).toList();
          _loadingTests = false;
        }),
      );
    } catch (e) {
      setState(() {
        _upcomingTests = [];
        _loadingTests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                onTap: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
                child: const ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeCard(context),
              const SizedBox(height: AppSpacing.lg),

              // My Courses Section
              _buildSectionHeader(
                context,
                'My Courses',
                Icons.school_outlined,
                onSeeAll: () => context.push(RouteNames.studentCourses),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildCoursesSection(),
              const SizedBox(height: AppSpacing.lg),

              // Upcoming Tests
              _buildSectionHeader(
                context,
                'Upcoming Tests',
                Icons.quiz_outlined,
                onSeeAll: () => context.push(RouteNames.studentTests),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildUpcomingTestsSection(),
              const SizedBox(height: AppSpacing.lg),

              // Performance Stats
              _buildSectionHeader(
                context,
                'Your Performance',
                Icons.bar_chart_outlined,
                onSeeAll: () => context.push(RouteNames.studentPerformance),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPerformanceSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Navigate based on selection
          switch (index) {
            case 1:
              context.push(RouteNames.studentCourses);
              break;
            case 2:
              context.push(RouteNames.studentTests);
              break;
            case 3:
              context.push(RouteNames.studentPerformance);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Tests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final userName = state.user?.displayName ?? 'Student';
        final greeting = _getGreeting();
        final badge = Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Icon(Icons.school, color: Colors.white, size: 32),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $userName! 👋',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Ready to continue your GRE preparation?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(alignment: Alignment.centerRight, child: badge),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting, $userName! 👋',
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Ready to continue your GRE preparation?',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        badge,
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildCoursesSection() {
    return BlocBuilder<CoursesBloc, CoursesState>(
      builder: (context, state) {
        if (state.status == CoursesStatus.loading) {
          return _buildShimmerCards(2);
        }

        if (state.status == CoursesStatus.failure) {
          return _buildErrorCard(
            state.errorMessage ?? 'Failed to load courses',
          );
        }

        if (state.courses.isEmpty) {
          return _buildEmptyCard(
            'No courses yet',
            'You haven\'t been enrolled in any courses.',
            Icons.school_outlined,
          );
        }

        return Column(
          children: state.courses.take(3).map((course) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildCourseCard(course),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCourseCard(CourseEntity course) {
    return InkWell(
      onTap: () => context.push('/student/courses/${course.id}'),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.book_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${course.materialCount} materials • ${course.testCount} tests',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTestsSection() {
    if (_loadingTests) {
      return _buildShimmerCards(1);
    }

    if (_upcomingTests.isEmpty) {
      return _buildEmptyCard(
        'No upcoming tests',
        'Check back later for scheduled tests.',
        Icons.quiz_outlined,
      );
    }

    return Column(
      children: _upcomingTests.map((test) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildTestCard(test),
        );
      }).toList(),
    );
  }

  Widget _buildTestCard(TestEntity test) {
    return InkWell(
      onTap: () => context.push('/student/tests/${test.id}'),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.quiz_outlined,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${test.totalQuestions} questions • ${test.duration} min',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_outline, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return BlocBuilder<PerformanceBloc, PerformanceState>(
      builder: (context, state) {
        if (state.status == PerformanceStatus.loading) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                  ? 2
                  : 1;
              const spacing = AppSpacing.sm;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(
                  4,
                  (_) => SizedBox(
                    width: itemWidth,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        final performance = state.performance;
        final verbal = performance?.verbalAccuracy.toStringAsFixed(0) ?? '--';
        final quant = performance?.quantAccuracy.toStringAsFixed(0) ?? '--';
        final tests = performance?.totalAttempts.toString() ?? '0';
        final trend = performance?.improvementTrend ?? 0;
        final trendStr = trend > 0
            ? '+${trend.toStringAsFixed(0)}%'
            : '${trend.toStringAsFixed(0)}%';

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 600
                ? 2
                : 1;
            const spacing = AppSpacing.sm;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            final cards = [
              _buildStatCard(
                verbal == '0' ? '--' : '$verbal%',
                'Verbal',
                AppColors.primary,
              ),
              _buildStatCard(
                quant == '0' ? '--' : '$quant%',
                'Quant',
                AppColors.secondary,
              ),
              _buildStatCard(tests, 'Tests', AppColors.success),
              _buildStatCard(
                trend == 0 ? '--' : trendStr,
                'Trend',
                AppColors.warning,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in cards)
                  SizedBox(width: itemWidth, child: card),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.statMedium.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: AppTextStyles.titleMedium),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }

  Widget _buildEmptyCard(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildShimmerCards(int count) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.surface,
      child: Column(
        children: List.generate(count, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          );
        }),
      ),
    );
  }
}
