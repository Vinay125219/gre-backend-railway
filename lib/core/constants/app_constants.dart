/// Application Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'EDU Learning Platform';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.techmigos.edu_learning_platform';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleStudent = 'student';

  // Test Types
  static const String testTypeFullMock = 'full_mock';
  static const String testTypeSectionTest = 'section_test';
  static const String testTypePractice = 'practice';

  // Question Types
  static const String questionTypeMcq = 'mcq';
  static const String questionTypeMsq = 'msq';
  static const String questionTypeNat = 'nat';

  // Material Types
  static const String materialTypePdf = 'pdf';
  static const String materialTypeVideo = 'video';
  static const String materialTypeNote = 'note';

  // GRE Sections
  static const String sectionVerbal = 'Verbal Reasoning';
  static const String sectionQuant = 'Quantitative Reasoning';
  static const String sectionAwa = 'Analytical Writing';

  static const List<String> greSections = [
    sectionVerbal,
    sectionQuant,
    sectionAwa,
  ];

  // Test Status
  static const String testStatusInProgress = 'in_progress';
  static const String testStatusCompleted = 'completed';
  static const String testStatusExpired = 'expired';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // File Limits
  static const int maxPdfSizeMb = 10;
  static const int maxImageSizeMb = 5;

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 24);
  static const Duration sessionTimeout = Duration(days: 7);

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Debounce Duration
  static const Duration debounceDuration = Duration(milliseconds: 500);
}
