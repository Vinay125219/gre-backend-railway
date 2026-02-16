import 'package:equatable/equatable.dart';
import '../../../../auth/domain/entities/user_entity.dart';

abstract class AdminStudentsEvent extends Equatable {
  const AdminStudentsEvent();

  @override
  List<Object?> get props => [];
}

class AdminStudentsLoadRequested extends AdminStudentsEvent {}

class AdminStudentCreateRequested extends AdminStudentsEvent {
  final String name;
  final String email;
  final String password;
  final List<String> assignedCourses;
  final DateTime? expiryDate;

  const AdminStudentCreateRequested({
    required this.name,
    required this.email,
    required this.password,
    this.assignedCourses = const [],
    this.expiryDate,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    assignedCourses,
    expiryDate,
  ];
}

class AdminStudentUpdateRequested extends AdminStudentsEvent {
  final UserEntity student;
  final String? password; // Optional if updating password
  final List<String>? assignedCourses;

  const AdminStudentUpdateRequested({
    required this.student,
    this.password,
    this.assignedCourses,
  });

  @override
  List<Object?> get props => [student, password, assignedCourses];
}
