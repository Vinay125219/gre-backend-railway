part of 'auth_bloc.dart';

/// Auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check current auth status on app start
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User login event
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// User logout event
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Password reset request
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Auth state changed (from stream)
class AuthStateChanged extends AuthEvent {
  final UserEntity? user;

  const AuthStateChanged({this.user});

  @override
  List<Object?> get props => [user];
}
