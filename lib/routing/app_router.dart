import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/go_router_refresh_stream.dart';

import '../core/constants/route_names.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/domain/entities/user_entity.dart';

// Student Screens
import '../features/student/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../features/student/courses/presentation/screens/courses_list_screen.dart';
import '../features/student/materials/presentation/screens/pdf_viewer_screen.dart';
import '../features/student/materials/presentation/screens/video_player_screen.dart';
import '../features/student/materials/presentation/screens/note_viewer_screen.dart';
import '../features/student/tests/presentation/screens/test_taking_screen.dart';
import '../features/student/tests/presentation/bloc/test_taking_bloc.dart';
import '../features/student/performance/presentation/screens/performance_screen.dart';

// Admin Screens
// Admin Screens
import '../features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/courses/presentation/screens/course_list_screen.dart';
import '../features/admin/students/presentation/screens/students_management_screen.dart';
import '../features/admin/students/presentation/screens/student_creation_screen.dart';
import '../features/admin/courses/presentation/screens/course_creation_screen.dart';
import '../features/student/courses/domain/entities/course_entity.dart';
import '../features/admin/content/presentation/screens/content_management_screen.dart';
import '../features/admin/tests/presentation/screens/tests_management_screen.dart';
import '../features/admin/tests/presentation/screens/test_creation_screen.dart';
import '../features/admin/tests/presentation/bloc/admin_tests_bloc.dart';
import '../features/admin/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../injection_container.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';

// Student Blocs for Provider injection
import '../features/student/courses/presentation/bloc/courses_bloc.dart';
import '../features/student/performance/presentation/bloc/performance_bloc.dart';

/// App router configuration using GoRouter
class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: _redirect,
    routes: [
      // Splash Screen
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login Screen
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ==================== SHARED VIEWER ROUTES ====================
      // PDF Viewer
      GoRoute(
        path: '/viewer/pdf/:materialId',
        name: 'pdfViewer',
        builder: (context, state) {
          final materialId = state.pathParameters['materialId'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Document';
          final url = state.uri.queryParameters['url'] ?? '';
          return PdfViewerScreen(
            materialId: materialId,
            title: title,
            url: url,
          );
        },
      ),

      // Video Player
      GoRoute(
        path: '/viewer/video/:materialId',
        name: 'videoPlayer',
        builder: (context, state) {
          final materialId = state.pathParameters['materialId'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Video';
          final url = state.uri.queryParameters['url'] ?? '';
          return VideoPlayerScreen(
            materialId: materialId,
            title: title,
            url: url,
          );
        },
      ),

      // Note Viewer
      GoRoute(
        path: '/viewer/note/:materialId',
        name: 'noteViewer',
        builder: (context, state) {
          final materialId = state.pathParameters['materialId'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Note';
          final content = state.uri.queryParameters['content'] ?? '';
          return NoteViewerScreen(
            materialId: materialId,
            title: title,
            content: Uri.decodeComponent(content),
          );
        },
      ),

      // ==================== STUDENT ROUTES ====================
      GoRoute(
        path: RouteNames.studentDashboard,
        name: 'studentDashboard',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<CoursesBloc>(create: (_) => di.sl<CoursesBloc>()),
            BlocProvider<PerformanceBloc>(
              create: (_) => di.sl<PerformanceBloc>(),
            ),
          ],
          child: const StudentDashboardScreen(),
        ),
        routes: [
          // Courses
          GoRoute(
            path: 'courses',
            name: 'studentCourses',
            builder: (context, state) => BlocProvider<CoursesBloc>(
              create: (_) => di.sl<CoursesBloc>(),
              child: const CoursesListScreen(),
            ),
          ),

          // Test Taking
          GoRoute(
            path: 'tests/:testId/take',
            name: 'studentTestTaking',
            builder: (context, state) {
              final testId = state.pathParameters['testId'] ?? '';
              final studentId = context.read<AuthBloc>().state.user?.id ?? '';
              if (studentId.isEmpty) {
                return const Scaffold(
                  body: Center(child: Text('Please sign in again.')),
                );
              }
              return BlocProvider(
                create: (context) => di.sl<TestTakingBloc>()
                  ..add(
                    TestTakingStarted(testId: testId, studentId: studentId),
                  ),
                child: TestTakingScreen(testId: testId),
              );
            },
          ),

          // Performance
          GoRoute(
            path: 'performance',
            name: 'studentPerformance',
            builder: (context, state) => BlocProvider<PerformanceBloc>(
              create: (_) => di.sl<PerformanceBloc>(),
              child: const PerformanceScreen(),
            ),
          ),
        ],
      ),

      // ==================== ADMIN ROUTES ====================
      GoRoute(
        path: RouteNames.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          // Students Management
          GoRoute(
            path: 'students',
            name: 'adminStudents',
            builder: (context, state) => const StudentsManagementScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'adminCreateStudent',
                builder: (context, state) => const StudentCreationScreen(),
              ),
              GoRoute(
                path: ':studentId',
                name: 'adminEditStudent',
                builder: (context, state) {
                  final student = state.extra as UserEntity?;
                  return StudentCreationScreen(studentToEdit: student);
                },
              ),
            ],
          ),

          // Course Management
          GoRoute(
            path: 'courses',
            name: 'adminCourses',
            builder: (context, state) => const CourseListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'adminCreateCourse',
                builder: (context, state) => const CourseCreationScreen(),
              ),
              GoRoute(
                path: ':courseId/edit',
                name: 'adminEditCourse',
                builder: (context, state) {
                  final course = state.extra as CourseEntity?;
                  return CourseCreationScreen(courseToEdit: course);
                },
              ),
            ],
          ),

          // Content Management
          GoRoute(
            path: 'content',
            name: 'adminContent',
            builder: (context, state) => const ContentManagementScreen(),
          ),

          // Tests Management
          GoRoute(
            path: 'tests',
            name: 'adminTests',
            builder: (context, state) => const TestsManagementScreen(),
            routes: [
              // Create Test (requires courseId query param)
              GoRoute(
                path: 'create',
                name: 'adminCreateTest',
                builder: (context, state) {
                  final courseId = state.uri.queryParameters['courseId'] ?? '';
                  return BlocProvider(
                    create: (_) => di.sl<AdminTestsBloc>(),
                    child: TestCreationScreen(courseId: courseId),
                  );
                },
              ),
              // Edit Test
              GoRoute(
                path: ':testId/edit',
                name: 'adminEditTest',
                builder: (context, state) {
                  final testId = state.pathParameters['testId'];
                  final courseId = state.uri.queryParameters['courseId'] ?? '';
                  return BlocProvider(
                    create: (_) => di.sl<AdminTestsBloc>(),
                    child: TestCreationScreen(
                      testId: testId,
                      courseId: courseId,
                    ),
                  );
                },
              ),
            ],
          ),

          // Analytics Dashboard
          GoRoute(
            path: 'analytics',
            name: 'adminAnalytics',
            builder: (context, state) => const AnalyticsDashboardScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  /// Global redirect logic for auth & role-based navigation
  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final isAuthRoute =
        state.matchedLocation == RouteNames.login ||
        state.matchedLocation == RouteNames.splash;

    // If not authenticated and trying to access protected route
    if (!isAuthenticated && !isAuthRoute) {
      return RouteNames.login;
    }

    // If authenticated and on login page, redirect to appropriate dashboard
    if (isAuthenticated && state.matchedLocation == RouteNames.login) {
      return authState.isAdmin
          ? RouteNames.adminDashboard
          : RouteNames.studentDashboard;
    }

    // Role-based route protection
    if (isAuthenticated) {
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      final isStudentRoute = state.matchedLocation.startsWith('/student');

      // Admin trying to access student routes - redirect to admin dashboard
      if (authState.isAdmin && isStudentRoute) {
        return RouteNames.adminDashboard;
      }

      // Student trying to access admin routes - redirect to student dashboard
      if (authState.isStudent && isAdminRoute) {
        return RouteNames.studentDashboard;
      }
    }

    return null; // No redirect needed
  }
}
