/// Named Route Constants
/// Centralized route names for type-safe navigation
class RouteNames {
  RouteNames._();

  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // Student Routes
  static const String studentDashboard = '/student';
  static const String studentCourses = '/student/courses';
  static const String studentCourseDetail = '/student/courses/:courseId';
  static const String studentMaterials = '/student/materials';

  static const String pdfViewer = '/viewer/pdf/:materialId';
  static const String videoPlayer = '/viewer/video/:materialId';
  static const String noteViewer = '/viewer/note/:materialId';
  static const String studentTests = '/student/tests';
  static const String studentTestInstructions =
      '/student/tests/:testId/instructions';
  static const String studentTestTaking = '/student/tests/:testId/take';
  static const String studentTestResults =
      '/student/tests/:testId/results/:attemptId';
  static const String studentPerformance = '/student/performance';
  static const String studentProfile = '/student/profile';

  // Admin Routes
  static const String adminDashboard = '/admin';
  static const String adminStudents = '/admin/students';
  static const String adminStudentDetail = '/admin/students/:studentId';
  static const String adminCreateStudent = '/admin/students/create';
  static const String adminCourses = '/admin/courses';
  static const String adminCourseDetail = '/admin/courses/:courseId';
  static const String adminCreateCourse = '/admin/courses/create';
  static const String adminContent = '/admin/content';
  static const String adminUploadPdf = '/admin/content/upload-pdf';
  static const String adminAddVideo = '/admin/content/add-video';
  static const String adminCreateNote = '/admin/content/create-note';
  static const String adminTests = '/admin/tests';
  static const String adminTestDetail = '/admin/tests/:testId';
  static const String adminCreateTest = '/admin/tests/create';
  static const String adminEditTest = '/admin/tests/:testId/edit';
  static const String adminAddQuestions = '/admin/tests/:testId/questions';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminSettings = '/admin/settings';
}
