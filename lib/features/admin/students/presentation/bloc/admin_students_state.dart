import 'package:equatable/equatable.dart';
import '../../../../auth/domain/entities/user_entity.dart';

enum AdminStudentsStatus {
  initial,
  loading,
  success,
  created,
  updated,
  failure,
}

class AdminStudentsState extends Equatable {
  final AdminStudentsStatus status;
  final List<UserEntity> students;
  final String? errorMessage;

  const AdminStudentsState({
    this.status = AdminStudentsStatus.initial,
    this.students = const [],
    this.errorMessage,
  });

  AdminStudentsState copyWith({
    AdminStudentsStatus? status,
    List<UserEntity>? students,
    String? errorMessage,
  }) {
    return AdminStudentsState(
      status: status ?? this.status,
      students: students ?? this.students,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, students, errorMessage];
}
