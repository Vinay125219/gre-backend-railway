import 'package:equatable/equatable.dart';
import '../../../../student/courses/domain/entities/course_entity.dart';

abstract class AdminCoursesEvent extends Equatable {
  const AdminCoursesEvent();

  @override
  List<Object?> get props => [];
}

class AdminCoursesLoadRequested extends AdminCoursesEvent {}

class AdminCourseCreateRequested extends AdminCoursesEvent {
  final CourseEntity course;
  final dynamic thumbnailFile; // Ideally File or Uint8List

  const AdminCourseCreateRequested({required this.course, this.thumbnailFile});

  @override
  List<Object?> get props => [course, thumbnailFile];
}

class AdminCourseUpdateRequested extends AdminCoursesEvent {
  final CourseEntity course;
  final dynamic newThumbnailFile;

  const AdminCourseUpdateRequested({
    required this.course,
    this.newThumbnailFile,
  });

  @override
  List<Object?> get props => [course, newThumbnailFile];
}

class AdminCourseDeleteRequested extends AdminCoursesEvent {
  final String courseId;

  const AdminCourseDeleteRequested(this.courseId);

  @override
  List<Object?> get props => [courseId];
}
