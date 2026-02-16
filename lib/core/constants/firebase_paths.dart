/// Firestore Collection Paths
/// Centralized path management for database operations
class FirebasePaths {
  FirebasePaths._();

  // Root Collections
  static const String users = 'users';
  static const String students = 'students';
  static const String courses = 'courses';
  static const String materials = 'materials';
  static const String tests = 'tests';
  static const String testAttempts = 'test_attempts';
  static const String analytics = 'analytics';
  static const String appConfig = 'app_config';

  // Subcollections
  static const String questions = 'questions';

  // Document Paths
  static String user(String uid) => '$users/$uid';
  static String student(String studentId) => '$students/$studentId';
  static String course(String courseId) => '$courses/$courseId';
  static String material(String materialId) => '$materials/$materialId';
  static String test(String testId) => '$tests/$testId';
  static String question(String testId, String questionId) =>
      '$tests/$testId/$questions/$questionId';
  static String testAttempt(String attemptId) => '$testAttempts/$attemptId';

  // Storage Paths
  static const String storagePdfs = 'pdfs';
  static const String storageImages = 'images';
  static const String storageProfilePictures = 'profile_pictures';

  static String pdfPath(String courseId, String fileName) =>
      '$storagePdfs/$courseId/$fileName';
  static String profilePicturePath(String userId) =>
      '$storageProfilePictures/$userId.jpg';
}
