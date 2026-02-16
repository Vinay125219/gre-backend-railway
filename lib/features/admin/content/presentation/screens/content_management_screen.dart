import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../../domain/entities/content_entity.dart';
import '../../../courses/domain/repositories/admin_course_repository.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';
import '../bloc/admin_content_bloc.dart';
import '../bloc/admin_content_event.dart';
import '../bloc/admin_content_state.dart';

/// Admin Content Management Screen
class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AdminCourseRepository _courseRepository;
  List<CourseEntity> _courses = [];
  bool _coursesLoading = false;
  String? _coursesError;
  // In a real app, we would fetch courses and populate this.
  // For now, we use a simple text input or predefined list for Course IDs.
  // Using a text controller for Course ID allows testing with any course.
  final TextEditingController _courseIdController = TextEditingController(
    text: 'all',
  );
  String _selectedCourseId = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _courseRepository = sl<AdminCourseRepository>();
    _loadCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _courseIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _coursesLoading = true;
      _coursesError = null;
    });

    final result = await _courseRepository.getAllCourses();
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
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AdminContentBloc>()
            ..add(const AdminContentLoadRequested(courseId: 'all')),
      child: BlocConsumer<AdminContentBloc, AdminContentState>(
        listener: (context, state) {
          if (state.status == AdminContentStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state.status == AdminContentStatus.success) {
            // maybe show success message?
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Content Management'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDFs'),
                  Tab(icon: Icon(Icons.video_library), text: 'Videos'),
                  Tab(icon: Icon(Icons.note_alt), text: 'Notes'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Course Filter
                _buildCourseFilterBar(context),

                if (state.status == AdminContentStatus.loading)
                  const LinearProgressIndicator(),

                // Content Lists
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContentList(state.pdfs, 'pdf', context),
                      _buildContentList(state.videos, 'video', context),
                      _buildContentList(state.notes, 'note', context),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddContentDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Content'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          final filterControl = _buildCourseFilterControl(context);
          final bulkButton = OutlinedButton.icon(
            onPressed: () => _showBulkUploadDialog(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('Bulk Upload'),
          );

          final content = isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    filterControl,
                    const SizedBox(height: AppSpacing.sm),
                    bulkButton,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: filterControl),
                    const SizedBox(width: AppSpacing.sm),
                    bulkButton,
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content,
              if (_coursesError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _coursesError!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
                TextButton.icon(
                  onPressed: _loadCourses,
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Retry loading courses'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCourseFilterControl(BuildContext context) {
    if (_courses.isNotEmpty) {
      final hasSelected =
          _selectedCourseId == 'all' ||
          _courses.any((course) => course.id == _selectedCourseId);
      final value = hasSelected ? _selectedCourseId : 'all';
      return DropdownButtonFormField<String>(
        key: ValueKey('course-filter-$value'),
        initialValue: value,
        isExpanded: true,
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
          _applyCourseFilter(context, value);
        },
        decoration: InputDecoration(
          labelText: 'Course',
          suffixIcon: _coursesLoading
              ? _buildInlineLoader()
              : IconButton(
                  tooltip: 'Reload courses',
                  icon: const Icon(Icons.sync),
                  onPressed: _loadCourses,
                ),
        ),
      );
    }

    return TextField(
      controller: _courseIdController,
      decoration: InputDecoration(
        labelText: 'Course ID',
        hintText: 'Enter Course ID or "all"',
        suffixIcon: _coursesLoading
            ? _buildInlineLoader()
            : IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Apply filter',
                onPressed: () =>
                    _applyCourseFilter(context, _courseIdController.text),
              ),
      ),
      onSubmitted: (value) => _applyCourseFilter(context, value),
    );
  }

  void _applyCourseFilter(BuildContext context, String value) {
    final selected = value.trim().isEmpty ? 'all' : value.trim();
    setState(() {
      _selectedCourseId = selected;
      _courseIdController.text = selected;
    });
    context.read<AdminContentBloc>().add(
      AdminContentLoadRequested(courseId: selected),
    );
  }

  Widget _buildInlineLoader() {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildContentList(
    List<ContentEntity> items,
    String type,
    BuildContext context,
  ) {
    Future<void> onRefresh() async {
      context.read<AdminContentBloc>().add(
        AdminContentLoadRequested(courseId: _selectedCourseId),
      );
    }

    final isEmpty = items.isEmpty;
    final content = isEmpty
        ? ListView(
            key: ValueKey('empty-$type'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildEmptyPlaceholder(
                type,
                onAdd: () => _showAddContentDialog(context),
              ),
            ],
          )
        : ListView.builder(
            key: ValueKey('list-$type-${items.length}'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (ctx, index) =>
                _buildContentCard(items[index], context),
          );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: content,
      ),
    );
  }

  Widget _buildContentCard(ContentEntity item, BuildContext context) {
    final isPdf = item.type == ContentType.pdf;
    final isVideo = item.type == ContentType.video;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPdf
                ? AppColors.error.withValues(alpha: 0.1)
                : isVideo
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            isPdf
                ? Icons.picture_as_pdf
                : isVideo
                ? Icons.play_circle
                : Icons.note,
            color: isPdf
                ? AppColors.error
                : isVideo
                ? AppColors.primary
                : AppColors.warning,
          ),
        ),
        title: Text(
          item.title,
          style: AppTextStyles.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Wrap(
          spacing: AppSpacing.sm,
          children: [
            _buildTag(item.section, AppColors.secondary),
            if (item.courseId.isNotEmpty)
              _buildTag('Course: ${item.courseId}', AppColors.textSecondary),

            // Show file size or duration if available in metadata
            if (item.metadata.containsKey('size'))
              Text(
                _formatBytes(item.metadata['size']),
                style: AppTextStyles.caption,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleContentAction(value, item, context),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  String _formatBytes(dynamic size) {
    if (size is int) {
      if (size < 1024) return '$size B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '';
  }

  Widget _buildTag(String label, Color color) {
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

  Widget _buildEmptyPlaceholder(String type, {VoidCallback? onAdd}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('No $type uploaded yet', style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add new content to keep students engaged.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAdd != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text('Add ${type.toUpperCase()}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleContentAction(
    String action,
    ContentEntity item,
    BuildContext context,
  ) async {
    switch (action) {
      case 'view':
        if (item.type == ContentType.pdf) {
          context.pushNamed(
            'pdfViewer',
            pathParameters: {'materialId': item.id},
            queryParameters: {'title': item.title, 'url': item.url},
          );
          return;
        } else if (item.type == ContentType.video) {
          context.pushNamed(
            'videoPlayer',
            pathParameters: {'materialId': item.id},
            queryParameters: {'title': item.title, 'url': item.url},
          );
          return;
        }
        final noteContent = item.description ?? '';
        context.pushNamed(
          'noteViewer',
          pathParameters: {'materialId': item.id},
          queryParameters: {
            'title': item.title,
            'content': Uri.encodeComponent(noteContent),
          },
        );
        break;
      case 'delete':
        _showDeleteConfirmation(item, context);
        break;
    }
  }

  void _showAddContentDialog(BuildContext mainContext) {
    if (_courses.isEmpty && _coursesError == null && !_coursesLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a course before adding content.')),
      );
      return;
    }

    // mainContext to access Bloc
    final currentTab = _tabController.index;
    final typeStr = currentTab == 0
        ? 'PDF'
        : currentTab == 1
        ? 'Video'
        : 'Note';

    final titleController = TextEditingController();
    final noteContentController = TextEditingController();
    final courseIdDialogController = TextEditingController(
      text: _selectedCourseId == 'all' ? '' : _selectedCourseId,
    );
    String selectedCourseId = _selectedCourseId == 'all'
        ? (_courses.isNotEmpty ? _courses.first.id : '')
        : _selectedCourseId;
    if (_courses.isNotEmpty &&
        !_courses.any((course) => course.id == selectedCourseId)) {
      selectedCourseId = _courses.first.id;
    }
    String section = 'verbal';
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add $typeStr'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_courses.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: ValueKey('course-dialog-$selectedCourseId'),
                      initialValue: selectedCourseId.isNotEmpty
                          ? selectedCourseId
                          : null,
                      isExpanded: true,
                      items: _courses
                          .map(
                            (course) => DropdownMenuItem(
                              value: course.id,
                              child: Text(
                                course.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedCourseId = value ?? ''),
                      decoration: const InputDecoration(labelText: 'Course'),
                    )
                  else
                    TextField(
                      controller: courseIdDialogController,
                      decoration: const InputDecoration(
                        labelText: 'Course ID',
                        helperText: 'Enter a valid course ID',
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: section,

                    decoration: const InputDecoration(labelText: 'Section'),
                    items: const [
                      DropdownMenuItem(
                        value: 'verbal',
                        child: Text('Verbal Reasoning'),
                      ),
                      DropdownMenuItem(
                        value: 'quant',
                        child: Text('Quantitative Reasoning'),
                      ),
                      DropdownMenuItem(
                        value: 'awa',
                        child: Text('Analytical Writing'),
                      ),
                    ],
                    onChanged: (value) => setState(() => section = value!),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (currentTab != 2) ...[
                    if (selectedFile != null)
                      Text('Selected: ${selectedFile!.name}'),

                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: currentTab == 0
                                ? ['pdf']
                                : ['mp4', 'mov', 'avi'],
                          );
                          if (result != null) {
                            setState(() => selectedFile = result.files.first);
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          'Choose ${currentTab == 0 ? "PDF" : "Video"}',
                        ),
                      ),
                    ),
                  ],

                  if (currentTab == 2)
                    TextField(
                      controller: noteContentController,
                      decoration: const InputDecoration(
                        labelText: 'Note Content',
                      ),
                      maxLines: 4,
                    ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final courseId = _courses.isNotEmpty
                  ? selectedCourseId
                  : courseIdDialogController.text.trim();
              if (titleController.text.isEmpty || courseId.isEmpty) {
                return; // Basic validation
              }

              if (currentTab == 2) {
                // Create Note
                mainContext.read<AdminContentBloc>().add(
                  AdminContentNoteCreated(
                    courseId: courseId,
                    title: titleController.text.trim(),
                    content: noteContentController.text.trim(),
                    section: section,
                  ),
                );
              } else {
                if (selectedFile != null) {
                  // Upload File
                  // We need to convert PlatformFile to File for our Repo.
                  // NOTE: For Web, we would use bytes. For Mobile, path.
                  if (selectedFile?.path != null) {
                    mainContext.read<AdminContentBloc>().add(
                      AdminContentUploadRequested(
                        file: File(selectedFile!.path!),
                        courseId: courseId,
                        title: titleController.text.trim(),
                        type: currentTab == 0
                            ? ContentType.pdf
                            : ContentType.video,
                        section: section,
                      ),
                    );
                  }
                }
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ContentEntity item, BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Content?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<AdminContentBloc>().add(
                AdminContentDeleteRequested(item),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBulkUploadDialog(BuildContext context) {
    // Left as future enhancement or exercise
    // Can iterate list and dispatch events
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Bulk Upload'),
        content: Text('Coming Soon'),
      ),
    );
  }
}
