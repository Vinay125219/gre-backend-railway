import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../injection_container.dart';
import '../../../../admin/content/domain/entities/content_entity.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../tests/domain/entities/test_entity.dart';
import '../../../tests/presentation/bloc/test_taking_bloc.dart';
import '../../../tests/presentation/screens/test_taking_screen.dart';
import '../bloc/course_details_bloc.dart';
import '../bloc/course_details_event.dart';
import '../bloc/course_details_state.dart';

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;
  final String contentId;

  const CourseDetailsScreen({
    super.key,
    required this.courseId,
    this.contentId = '',
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final studentId = authState.user?.id ?? '';

    return BlocProvider(
      create: (context) => sl<CourseDetailsBloc>()
        ..add(
          CourseDetailsLoadRequested(courseId: courseId, studentId: studentId),
        ),
      child: BlocBuilder<CourseDetailsBloc, CourseDetailsState>(
        builder: (context, state) {
          if (state.status == CourseDetailsStatus.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state.status == CourseDetailsStatus.failure) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text(state.errorMessage ?? 'Unknown error')),
            );
          }

          if (state.status == CourseDetailsStatus.success &&
              state.course != null) {
            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(state.course!.title),
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Materials'),
                      Tab(text: 'Mock Tests'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    _buildMaterialsTab(context, state, studentId),
                    _buildTestsTab(context, state, studentId),
                  ],
                ),
              ),
            );
          }

          return const SizedBox(); // Initial state
        },
      ),
    );
  }

  Widget _buildMaterialsTab(
    BuildContext context,
    CourseDetailsState state,
    String studentId,
  ) {
    Future<void> refresh() async {
      context.read<CourseDetailsBloc>().add(
        CourseDetailsLoadRequested(courseId: courseId, studentId: studentId),
      );
    }

    if (state.content.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            SizedBox(height: AppSpacing.xxl),
            Center(child: Text('No materials available')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          double childAspectRatio = 3.2;

          if (constraints.maxWidth >= 1100) {
            crossAxisCount = 3;
            childAspectRatio = 2.2;
          } else if (constraints.maxWidth >= 700) {
            crossAxisCount = 2;
            childAspectRatio = 2.6;
          }

          if (crossAxisCount == 1) {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.content.length,
              itemBuilder: (context, index) {
                return _buildMaterialCard(context, state.content[index]);
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
            itemCount: state.content.length,
            itemBuilder: (context, index) {
              return _buildMaterialCard(context, state.content[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTestsTab(
    BuildContext context,
    CourseDetailsState state,
    String studentId,
  ) {
    Future<void> refresh() async {
      context.read<CourseDetailsBloc>().add(
        CourseDetailsLoadRequested(courseId: courseId, studentId: studentId),
      );
    }

    if (state.tests.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            SizedBox(height: AppSpacing.xxl),
            Center(child: Text('No mock tests available')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          double childAspectRatio = 2.8;

          if (constraints.maxWidth >= 1100) {
            crossAxisCount = 3;
            childAspectRatio = 2.0;
          } else if (constraints.maxWidth >= 700) {
            crossAxisCount = 2;
            childAspectRatio = 2.3;
          }

          if (crossAxisCount == 1) {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.tests.length,
              itemBuilder: (context, index) {
                return _buildTestCard(context, state.tests[index], studentId);
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
            itemCount: state.tests.length,
            itemBuilder: (context, index) {
              return _buildTestCard(context, state.tests[index], studentId);
            },
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, ContentEntity item) {
    return Card(
      child: ListTile(
        leading: Icon(
          item.type == ContentType.pdf
              ? Icons.picture_as_pdf
              : item.type == ContentType.video
              ? Icons.play_circle
              : Icons.note,
          color: AppColors.primary,
        ),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.section),
        trailing: const Icon(Icons.open_in_new),
        onTap: () async {
          if (item.type == ContentType.pdf) {
            if (item.url.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF URL is missing')),
              );
              return;
            }
            context.pushNamed(
              'pdfViewer',
              pathParameters: {'materialId': item.id},
              queryParameters: {'title': item.title, 'url': item.url},
            );
          } else if (item.type == ContentType.video) {
            if (item.url.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video URL is missing')),
              );
              return;
            }
            context.pushNamed(
              'videoPlayer',
              pathParameters: {'materialId': item.id},
              queryParameters: {'title': item.title, 'url': item.url},
            );
          } else {
            final noteContent = item.description ?? '';
            context.pushNamed(
              'noteViewer',
              pathParameters: {'materialId': item.id},
              queryParameters: {
                'title': item.title,
                'content': Uri.encodeComponent(noteContent),
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context,
    TestEntity test,
    String studentId,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.quiz, color: AppColors.secondary),
        title: Text(test.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${test.duration} mins • ${test.totalMarks} marks'),
        trailing: ElevatedButton(
          onPressed: () {
            if (studentId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please sign in again')),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => sl<TestTakingBloc>()
                    ..add(
                      TestTakingStarted(testId: test.id, studentId: studentId),
                    ),
                  child: TestTakingScreen(testId: test.id),
                ),
              ),
            );
          },
          child: const Text('Start'),
        ),
      ),
    );
  }
}
