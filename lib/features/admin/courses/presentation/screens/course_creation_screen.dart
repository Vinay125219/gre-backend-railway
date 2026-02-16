import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';
import '../bloc/admin_courses_bloc.dart';
import '../bloc/admin_courses_event.dart';
import '../bloc/admin_courses_state.dart';

class CourseCreationScreen extends StatefulWidget {
  final CourseEntity? courseToEdit;

  const CourseCreationScreen({super.key, this.courseToEdit});

  @override
  State<CourseCreationScreen> createState() => _CourseCreationScreenState();
}

class _CourseCreationScreenState extends State<CourseCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _published;
  List<String> _selectedSections = [];
  dynamic _selectedThumbnail; // PlatformFile or similar
  bool _pendingSave = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.courseToEdit?.title);
    _descriptionController = TextEditingController(
      text: widget.courseToEdit?.description,
    );
    _published = widget.courseToEdit?.published ?? false;
    _selectedSections = List.from(widget.courseToEdit?.sections ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    if (_pendingSave) return;
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedSections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one section')),
        );
        return;
      }

      setState(() => _pendingSave = true);

      final course = CourseEntity(
        id:
            widget.courseToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch
                .toString(), // Generate ID if new
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        thumbnailUrl: widget
            .courseToEdit
            ?.thumbnailUrl, // Handled by Bloc along with file
        sections: _selectedSections,
        published: _published,
        createdAt: widget.courseToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bloc = context.read<AdminCoursesBloc>();
      if (widget.courseToEdit == null) {
        bloc.add(
          AdminCourseCreateRequested(
            course: course,
            thumbnailFile: _selectedThumbnail,
          ),
        );
      } else {
        bloc.add(
          AdminCourseUpdateRequested(
            course: course,
            newThumbnailFile: _selectedThumbnail,
          ),
        );
      }
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _selectedThumbnail = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we were navigated here, we likely need a BlocProvider if not already provided.
    // However, CourseListScreen provides it scoped. If we Navigated PUSH, we might be out of scope.
    // Usually standard GoRouter push keeps context? No, it's a new route.
    // Does AppRouter provide AdminCoursesBloc globally? No, standard practice is to provide it or use DI.
    // let's wrap in BlocProvider using DI.

    return BlocProvider(
      create: (context) => sl<AdminCoursesBloc>(),
      child: BlocConsumer<AdminCoursesBloc, AdminCoursesState>(
        listener: (context, state) {
          if (_pendingSave && state.status == AdminCoursesStatus.failure) {
            setState(() => _pendingSave = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error saving course'),
                backgroundColor: AppColors.error,
              ),
            );
          }

          if (_pendingSave && state.status == AdminCoursesStatus.success) {
            setState(() => _pendingSave = false);
            Navigator.pop(context, 'saved');
          }
        },
        builder: (context, state) {
          final isSaving =
              _pendingSave && state.status == AdminCoursesStatus.loading;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.courseToEdit == null ? 'New Course' : 'Edit Course',
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => _onSave(context),
                  child: state.status == AdminCoursesStatus.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final content = Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Picker
                      GestureDetector(
                        onTap: isSaving ? null : _pickThumbnail,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            key: ValueKey(
                              _selectedThumbnail != null ||
                                  widget.courseToEdit?.thumbnailUrl != null,
                            ),
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              image:
                                  _selectedThumbnail == null &&
                                      widget.courseToEdit?.thumbnailUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.courseToEdit!.thumbnailUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: _selectedThumbnail != null
                                ? const Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                      size: 40,
                                    ),
                                  )
                                : widget.courseToEdit?.thumbnailUrl == null
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 40,
                                        color: AppColors.textSecondary,
                                      ),
                                      SizedBox(height: AppSpacing.sm),
                                      Text('Add Cover Image'),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Course Title',
                          hintText: 'e.g., Complete GRE Verbal Prep',
                        ),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Course overview...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Sections
                      Row(
                        children: [
                          Text('Sections', style: AppTextStyles.titleSmall),
                          const Spacer(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _selectedSections.isEmpty
                                  ? 'None selected'
                                  : '${_selectedSections.length} selected',
                              key: ValueKey(_selectedSections.length),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _selectedSections.isEmpty
                                    ? AppColors.textTertiary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Custom Section Input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(),
                              decoration: InputDecoration(
                                labelText: 'Add Custom Section',
                                hintText: 'e.g., Vocabulary',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _showAddSectionDialog,
                                ),
                              ),
                              readOnly: true,
                              onTap: _showAddSectionDialog,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children:
                            [
                              'Verbal Reasoning',
                              'Quantitative Reasoning',
                              'Analytical Writing',
                              ..._selectedSections.where(
                                (s) => ![
                                  'Verbal Reasoning',
                                  'Quantitative Reasoning',
                                  'Analytical Writing',
                                ].contains(s),
                              ),
                            ].map((section) {
                              final isSelected = _selectedSections.contains(
                                section,
                              );
                              return FilterChip(
                                label: Text(section),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSections.add(section);
                                    } else {
                                      _selectedSections.remove(section);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Published Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Published'),
                        subtitle: const Text(
                          'Make this course visible to students',
                        ),
                        value: _published,
                        onChanged: (v) => setState(() => _published = v),
                      ),
                    ],
                  ),
                );

                if (!isWide) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: content,
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: content,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddSectionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Section'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Section Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final section = controller.text.trim();
              if (section.isNotEmpty) {
                setState(() {
                  if (!_selectedSections.contains(section)) {
                    _selectedSections.add(section);
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
