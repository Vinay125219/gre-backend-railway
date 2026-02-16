import 'package:get_it/get_it.dart';

// Auth Feature
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Student Courses Feature
import 'features/student/courses/data/repositories/course_repository_impl.dart';
import 'features/student/courses/domain/repositories/course_repository.dart';
import 'features/student/courses/presentation/bloc/courses_bloc.dart';
import 'features/student/courses/presentation/bloc/course_details_bloc.dart';

// Student Materials Feature
import 'features/student/materials/data/repositories/material_repository_impl.dart';
import 'features/student/materials/domain/repositories/material_repository.dart';

// Student Tests Feature
import 'features/student/tests/data/repositories/test_repository_impl.dart';
import 'features/student/tests/domain/repositories/test_repository.dart';
import 'features/student/tests/presentation/bloc/test_taking_bloc.dart';

// Student Performance Feature
import 'features/student/performance/data/repositories/performance_repository_impl.dart';
import 'features/student/performance/domain/repositories/performance_repository.dart';
import 'features/student/performance/presentation/bloc/performance_bloc.dart';

// Admin Courses Feature
import 'features/admin/courses/data/repositories/admin_course_repository_impl.dart';
import 'features/admin/courses/domain/repositories/admin_course_repository.dart';
import 'features/admin/courses/presentation/bloc/admin_courses_bloc.dart';

// Admin Students Feature
import 'features/admin/students/data/repositories/admin_student_repository_impl.dart';
import 'features/admin/students/domain/repositories/admin_student_repository.dart';
import 'features/admin/students/presentation/bloc/admin_students_bloc.dart';

// Admin Content Feature
import 'features/admin/content/data/repositories/admin_content_repository_impl.dart';
import 'features/admin/content/domain/repositories/admin_content_repository.dart';
import 'features/admin/content/presentation/bloc/admin_content_bloc.dart';

// Admin Analytics Feature
import 'features/admin/analytics/data/repositories/admin_analytics_repository_impl.dart';
import 'features/admin/analytics/domain/repositories/admin_analytics_repository.dart';
import 'features/admin/analytics/presentation/bloc/admin_analytics_bloc.dart';

// Admin Tests Feature
import 'features/admin/tests/data/repositories/admin_test_repository_impl.dart';
import 'features/admin/tests/domain/repositories/admin_test_repository.dart';
import 'features/admin/tests/presentation/bloc/admin_tests_bloc.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  _initExternalDependencies();

  _initAuthFeature();
  _initCoursesFeature();
  _initMaterialsFeature();
  _initTestsFeature();
  _initPerformanceFeature();
  _initAdminFeatures();
}

/// Initialize external dependencies.
/// No external backend dependencies are required in local mock mode.
void _initExternalDependencies() {}

/// Initialize Auth feature dependencies
void _initAuthFeature() {
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

  // Must stay singleton so router and UI share a single auth state.
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
}

/// Initialize Courses feature dependencies
void _initCoursesFeature() {
  sl.registerLazySingleton<CourseRepository>(() => CourseRepositoryImpl());

  sl.registerFactory<CoursesBloc>(
    () => CoursesBloc(courseRepository: sl<CourseRepository>()),
  );
  sl.registerFactory<CourseDetailsBloc>(
    () => CourseDetailsBloc(
      courseRepository: sl<CourseRepository>(),
      testRepository: sl<TestRepository>(),
      contentRepository: sl<AdminContentRepository>(),
    ),
  );
}

/// Initialize Materials feature dependencies
void _initMaterialsFeature() {
  sl.registerLazySingleton<MaterialRepository>(() => MaterialRepositoryImpl());
}

/// Initialize Tests feature dependencies
void _initTestsFeature() {
  sl.registerLazySingleton<TestRepository>(() => TestRepositoryImpl());

  sl.registerFactory<TestTakingBloc>(
    () => TestTakingBloc(testRepository: sl<TestRepository>()),
  );
}

/// Initialize Performance feature dependencies
void _initPerformanceFeature() {
  sl.registerLazySingleton<PerformanceRepository>(
    () => PerformanceRepositoryImpl(),
  );

  sl.registerFactory<PerformanceBloc>(
    () => PerformanceBloc(repository: sl<PerformanceRepository>()),
  );
}

/// Initialize Admin features dependencies
void _initAdminFeatures() {
  sl.registerLazySingleton<AdminCourseRepository>(
    () => AdminCourseRepositoryImpl(),
  );
  sl.registerFactory<AdminCoursesBloc>(
    () => AdminCoursesBloc(repository: sl<AdminCourseRepository>()),
  );

  sl.registerLazySingleton<AdminStudentRepository>(
    () => AdminStudentRepositoryImpl(),
  );
  sl.registerFactory<AdminStudentsBloc>(
    () => AdminStudentsBloc(repository: sl<AdminStudentRepository>()),
  );

  sl.registerLazySingleton<AdminContentRepository>(
    () => AdminContentRepositoryImpl(),
  );
  sl.registerFactory<AdminContentBloc>(
    () => AdminContentBloc(repository: sl<AdminContentRepository>()),
  );

  sl.registerLazySingleton<AdminAnalyticsRepository>(
    () => AdminAnalyticsRepositoryImpl(),
  );
  sl.registerFactory<AdminAnalyticsBloc>(
    () => AdminAnalyticsBloc(repository: sl<AdminAnalyticsRepository>()),
  );

  sl.registerLazySingleton<AdminTestRepository>(
    () => AdminTestRepositoryImpl(),
  );
  sl.registerFactory<AdminTestsBloc>(
    () => AdminTestsBloc(repository: sl<AdminTestRepository>()),
  );
}
