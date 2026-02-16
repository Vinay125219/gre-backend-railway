import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../bloc/admin_students_bloc.dart';
import '../bloc/admin_students_event.dart';
import '../bloc/admin_students_state.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../courses/domain/repositories/admin_course_repository.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';
import '../../domain/repositories/admin_student_repository.dart';

class StudentCreationScreen extends StatefulWidget {
  final UserEntity? studentToEdit;

  const StudentCreationScreen({super.key, this.studentToEdit});

  @override
  State<StudentCreationScreen> createState() => _StudentCreationScreenState();
}

class _StudentCreationScreenState extends State<StudentCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _expiryDate;
  bool _isLoading = false;
  late final AdminCourseRepository _courseRepository;
  late final AdminStudentRepository _studentRepository;
  List<CourseEntity> _courses = [];
  bool _coursesLoading = false;
  String? _coursesError;
  bool _assignedLoading = false;
  final Set<String> _selectedCourseIds = {};

  @override
  void initState() {
    super.initState();
    _courseRepository = sl<AdminCourseRepository>();
    _studentRepository = sl<AdminStudentRepository>();
    if (widget.studentToEdit != null) {
      _nameController.text = widget.studentToEdit!.displayName;
      _emailController.text = widget.studentToEdit!.email;
      _expiryDate = widget.studentToEdit!.expiryDate;
      _loadAssignedCourses(widget.studentToEdit!.id);
    }
    _loadCourses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.studentToEdit != null) {
        // Edit Mode
        context.read<AdminStudentsBloc>().add(
          AdminStudentUpdateRequested(
            student: widget.studentToEdit!.copyWith(
              displayName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              expiryDate: _expiryDate,
            ),
            password: _passwordController.text.isNotEmpty
                ? _passwordController.text
                : null,
            assignedCourses: _selectedCourseIds.toList(),
          ),
        );
      } else {
        // Create Mode
        context.read<AdminStudentsBloc>().add(
          AdminStudentCreateRequested(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            expiryDate: _expiryDate,
            assignedCourses: _selectedCourseIds.toList(),
          ),
        );
      }
    }
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

  Future<void> _loadAssignedCourses(String studentId) async {
    setState(() {
      _assignedLoading = true;
    });
    final result = await _studentRepository.getAssignedCourses(studentId);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _assignedLoading = false),
      (courseIds) => setState(() {
        _assignedLoading = false;
        _selectedCourseIds
          ..clear()
          ..addAll(courseIds);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminStudentsBloc>(),
      child: BlocConsumer<AdminStudentsBloc, AdminStudentsState>(
        listener: (context, state) {
          if (!mounted) return;

          final isLoading = state.status == AdminStudentsStatus.loading;
          if (_isLoading != isLoading) {
            setState(() => _isLoading = isLoading);
          }

          if (state.status == AdminStudentsStatus.created ||
              state.status == AdminStudentsStatus.updated) {
            Navigator.pop(
              context,
              state.status == AdminStudentsStatus.created
                  ? 'created'
                  : 'updated',
            );
          }

          if (state.status == AdminStudentsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error creating student'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.studentToEdit == null ? 'New Student' : 'Edit Student',
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      // Disable email editing in update mode (optional, but safer for auth sync)
                      enabled: widget.studentToEdit == null,
                      validator: (v) =>
                          v?.contains('@') ?? false ? null : 'Invalid email',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: widget.studentToEdit == null
                            ? 'Password'
                            : 'New Password (Optional)',
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (widget.studentToEdit != null &&
                            (v?.isEmpty ?? true)) {
                          return null; // Optional in edit
                        }
                        return (v?.length ?? 0) < 6 ? 'Min 6 characters' : null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Expiry Date Picker
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Account Expiry Date (Optional)',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _expiryDate != null
                              ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                              : 'No expiry date set',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCourseAssignment(),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(AppSpacing.md),
                        ),
                        // Pass the builder context to _onSubmit
                        onPressed:
                            _isLoading || _coursesLoading || _assignedLoading
                            ? null
                            : () => _onSubmit(context),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                widget.studentToEdit == null
                                    ? 'Create Student'
                                    : 'Update Student',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseAssignment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assign Courses', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        if (_coursesLoading || _assignedLoading)
          const LinearProgressIndicator(),
        if (_coursesError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _coursesError!,
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
          TextButton.icon(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry loading courses'),
          ),
        ] else if (_courses.isEmpty)
          Text('No courses available yet.', style: AppTextStyles.bodySmall)
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _courses.map((course) {
              final selected = _selectedCourseIds.contains(course.id);
              return FilterChip(
                label: Text(course.title, overflow: TextOverflow.ellipsis),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedCourseIds.add(course.id);
                    } else {
                      _selectedCourseIds.remove(course.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
