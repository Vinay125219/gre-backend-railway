import 'package:equatable/equatable.dart';

abstract class CourseDetailsEvent extends Equatable {
  const CourseDetailsEvent();

  @override
  List<Object?> get props => [];
}

class CourseDetailsLoadRequested extends CourseDetailsEvent {
  final String courseId;
  final String
  studentId; // Needed for specific logic if any, currently just passing courseId mainly

  const CourseDetailsLoadRequested({
    required this.courseId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [courseId, studentId];
}
