import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/route_names.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../content/domain/repositories/admin_content_repository.dart';
import '../../../courses/domain/repositories/admin_course_repository.dart';
import '../../../students/domain/repositories/admin_student_repository.dart';
import '../../../tests/domain/repositories/admin_test_repository.dart';

/// Admin Dashboard Screen.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  int _studentCount = 0;
  int _courseCount = 0;
  int _testCount = 0;
  int _materialCount = 0;
  late final AdminStudentRepository _studentRepository;
  late final AdminCourseRepository _courseRepository;
  late final AdminTestRepository _testRepository;
  late final AdminContentRepository _contentRepository;

  @override
  void initState() {
    super.initState();
    _studentRepository = sl<AdminStudentRepository>();
    _courseRepository = sl<AdminCourseRepository>();
    _testRepository = sl<AdminTestRepository>();
    _contentRepository = sl<AdminContentRepository>();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoading = true);

    try {
      final studentsResult = await _studentRepository.getAllStudents();
      final coursesResult = await _courseRepository.getAllCourses();
      final testsResult = await _testRepository.getAllTests();
      final contentResult = await _contentRepository.getAllContent();

      if (mounted) {
        setState(() {
          _studentCount = studentsResult.fold(
            (_) => 0,
            (items) => items.length,
          );
          _courseCount = coursesResult.fold((_) => 0, (items) => items.length);
          _testCount = testsResult.fold((_) => 0, (items) => items.length);
          _materialCount = contentResult.fold(
            (_) => 0,
            (items) => items.length,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
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
        onRefresh: _loadDashboardStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Overview
              _buildStatsRow(context),
              const SizedBox(height: AppSpacing.lg),

              // Quick Actions
              _buildSectionHeader(context, 'Quick Actions'),
              const SizedBox(height: AppSpacing.sm),
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.lg),

              // Today's Activity
              _buildSectionHeader(context, 'System Status'),
              const SizedBox(height: AppSpacing.sm),
              _buildActivityCard(context),
              const SizedBox(height: AppSpacing.lg),

              // Data Status
              _buildSectionHeader(context, 'Data Status'),
              const SizedBox(height: AppSpacing.sm),
              _buildDatabaseStatus(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 1:
              context.push(RouteNames.adminStudents);
              break;
            case 2:
              context.push(RouteNames.adminContent);
              break;
            case 3:
              context.push(RouteNames.adminTests);
              break;
            case 4:
              context.push(RouteNames.adminAnalytics);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Content',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Tests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsForWidth(constraints.maxWidth, maxColumns: 3);
        const spacing = AppSpacing.sm;
        final itemWidth = _itemWidth(constraints.maxWidth, columns, spacing);

        final cards = _isLoading
            ? [
                _buildLoadingStatCard(),
                _buildLoadingStatCard(),
                _buildLoadingStatCard(),
              ]
            : [
                _buildStatCard(
                  context,
                  _studentCount.toString(),
                  'Students',
                  Icons.people,
                  AppColors.primary,
                  () => context.push(RouteNames.adminStudents),
                ),
                _buildStatCard(
                  context,
                  _courseCount.toString(),
                  'Courses',
                  Icons.school,
                  AppColors.secondary,
                  () => context.push(RouteNames.adminCourses),
                ),
                _buildStatCard(
                  context,
                  _testCount.toString(),
                  'Tests',
                  Icons.quiz,
                  AppColors.success,
                  () => context.push(RouteNames.adminTests),
                ),
              ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _buildLoadingStatCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(value, style: AppTextStyles.statMedium),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(title, style: AppTextStyles.titleMedium);
  }

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _actionColumnsForWidth(constraints.maxWidth);
        const spacing = AppSpacing.sm;
        final itemWidth = _itemWidth(constraints.maxWidth, columns, spacing);

        final actions = [
          _buildActionButton(
            context,
            Icons.person_add,
            'Add Student',
            AppColors.primary,
            _openStudentCreator,
          ),
          _buildActionButton(
            context,
            Icons.add_box,
            'New Course',
            AppColors.secondary,
            () => context.push(RouteNames.adminCreateCourse),
          ),
          _buildActionButton(
            context,
            Icons.upload_file,
            'Upload',
            AppColors.info,
            () => context.push(RouteNames.adminContent),
          ),
          _buildActionButton(
            context,
            Icons.add_task,
            'Create Test',
            AppColors.success,
            () => context.push(RouteNames.adminCreateTest),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(width: itemWidth, child: action),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _columnsForWidth(double width, {int maxColumns = 3}) {
    if (width >= 900) {
      return maxColumns;
    }
    if (width >= 600) {
      return maxColumns >= 2 ? 2 : 1;
    }
    return 1;
  }

  int _actionColumnsForWidth(double width) {
    if (width >= 1200) return 4;
    if (width >= 700) return 2;
    return 1;
  }

  double _itemWidth(double width, int columns, double spacing) {
    final totalSpacing = spacing * (columns - 1);
    return (width - totalSpacing) / columns;
  }

  Future<void> _openStudentCreator() async {
    final result = await context.push(RouteNames.adminCreateStudent);
    if (!mounted) return;
    if (result == 'created') {
      _loadDashboardStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student created successfully')),
      );
    }
  }

  Widget _buildActivityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildActivityItem(
            Icons.developer_board,
            'Running in local mock mode',
            AppColors.info,
          ),
          const Divider(),
          _buildActivityItem(
            Icons.cloud_queue,
            'Railway backend not connected yet',
            AppColors.warning,
          ),
          const Divider(),
          _buildActivityItem(
            Icons.check_circle_outline,
            'Workspace is ready for GitHub + Railway setup',
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildDatabaseStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildStatusRow('Students', _studentCount),
          const Divider(),
          _buildStatusRow('Courses', _courseCount),
          const Divider(),
          _buildStatusRow('Tests', _testCount),
          const Divider(),
          _buildStatusRow('Materials', _materialCount),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String collection, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(collection, style: AppTextStyles.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: count > 0
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '$count docs',
              style: AppTextStyles.labelSmall.copyWith(
                color: count > 0 ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
