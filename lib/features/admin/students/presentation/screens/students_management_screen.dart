import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../bloc/admin_students_bloc.dart';
import '../bloc/admin_students_event.dart';
import '../bloc/admin_students_state.dart';

/// Admin Students Management Screen
class StudentsManagementScreen extends StatelessWidget {
  const StudentsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AdminStudentsBloc>()..add(AdminStudentsLoadRequested()),
      child: const _StudentsManagementView(),
    );
  }
}

class _StudentsManagementView extends StatefulWidget {
  const _StudentsManagementView();

  @override
  State<_StudentsManagementView> createState() =>
      _StudentsManagementViewState();
}

class _StudentsManagementViewState extends State<_StudentsManagementView> {
  final _searchController = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminStudentsBloc>().add(
                AdminStudentsLoadRequested(),
              );
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting students...')),
              );
            },
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: BlocBuilder<AdminStudentsBloc, AdminStudentsState>(
        builder: (context, state) {
          final content = _buildBodyContent(context, state, isMobile);
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: content,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openStudentEditor,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    AdminStudentsState state,
    bool isMobile,
  ) {
    if (state.status == AdminStudentsStatus.loading) {
      return const Center(
        key: ValueKey('students-loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (state.status == AdminStudentsStatus.failure) {
      return Center(
        key: const ValueKey('students-error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.errorMessage ?? 'Failed to load students',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AdminStudentsBloc>().add(
                  AdminStudentsLoadRequested(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final students = _getFilteredStudents(state.students);
    final padding = isMobile ? AppSpacing.sm : AppSpacing.md;

    return Column(
      key: const ValueKey('students-loaded'),
      children: [
        // Search & Filter Bar
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: isMobile ? _buildMobileSearchBar() : _buildDesktopSearchBar(),
        ),

        // Stats Bar
        Container(
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatChip(
                  'Total: ${state.students.length}',
                  AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildStatChip(
                  'Active: ${state.students.where((s) => !s.isExpired && !s.disabled).length}',
                  AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildStatChip(
                  'Expired: ${state.students.where((s) => s.isExpired).length}',
                  AppColors.error,
                ),
              ],
            ),
          ),
        ),

        // Students List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<AdminStudentsBloc>().add(
                AdminStudentsLoadRequested(),
              );
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: students.isEmpty
                  ? ListView(
                      key: const ValueKey('students-empty'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(padding),
                      children: [_buildEmptyState()],
                    )
                  : ListView.builder(
                      key: ValueKey('students-${students.length}'),
                      padding: EdgeInsets.all(padding),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        return _buildStudentCard(students[index]);
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search students...',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'active', label: Text('Active')),
              ButtonSegment(value: 'expired', label: Text('Expired')),
            ],
            selected: {_filter},
            onSelectionChanged: (value) {
              setState(() => _filter = value.first);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('All')),
            ButtonSegment(value: 'active', label: Text('Active')),
            ButtonSegment(value: 'expired', label: Text('Expired')),
          ],
          selected: {_filter},
          onSelectionChanged: (value) {
            setState(() => _filter = value.first);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('No students found', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Invite students to start tracking their progress.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: _openStudentEditor,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  List<UserEntity> _getFilteredStudents(List<UserEntity> students) {
    var filtered = students;

    // Apply filter
    if (_filter == 'active') {
      filtered = filtered.where((s) => !s.isExpired && !s.disabled).toList();
    } else if (_filter == 'expired') {
      filtered = filtered.where((s) => s.isExpired).toList();
    }

    // Apply search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (s) =>
                s.displayName.toLowerCase().contains(query) ||
                s.email.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
  }

  Widget _buildStatChip(String label, Color color) {
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

  Widget _buildStudentCard(UserEntity student) {
    final isExpired = student.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpired
              ? AppColors.errorLight
              : AppColors.primaryContainer,
          child: Text(
            student.initials,
            style: TextStyle(
              color: isExpired ? AppColors.error : AppColors.primary,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student.displayName,
                style: AppTextStyles.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isExpired)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'EXPIRED',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.email,
              style: AppTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
            if (student.expiryDate != null)
              Text(
                'Expires: ${_formatDate(student.expiryDate!)}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isExpired ? AppColors.error : AppColors.textSecondary,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) => _handleMenuAction(value, student),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    student.disabled ? Icons.check_circle : Icons.block,
                    size: 18,
                    color: student.disabled
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(student.disabled ? 'Enable' : 'Disable'),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: student.expiryDate != null,
        onTap: () => _openStudentEditor(student: student),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(String action, UserEntity student) {
    switch (action) {
      case 'view':
      case 'edit':
        _openStudentEditor(student: student);
        break;
      case 'toggle':
        // Update student via Bloc
        context.read<AdminStudentsBloc>().add(
          AdminStudentUpdateRequested(
            student: student.copyWith(disabled: !student.disabled),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              student.disabled
                  ? '${student.displayName} enabled'
                  : '${student.displayName} disabled',
            ),
          ),
        );
        break;
    }
  }

  Future<void> _openStudentEditor({UserEntity? student}) async {
    final router = GoRouter.of(context);
    final result = student == null
        ? await router.push('/admin/students/create')
        : await router.push('/admin/students/${student.id}', extra: student);

    if (!mounted) return;

    if (result == 'created' || result == 'updated') {
      context.read<AdminStudentsBloc>().add(AdminStudentsLoadRequested());
      final message = result == 'created'
          ? 'Student created successfully'
          : 'Student updated successfully';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
