part of 'auth_bloc.dart';

/// Auth status enum
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Auth states
class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;
  final bool passwordResetSent;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.passwordResetSent = false,
  });

  /// Initial unknown state
  const AuthState.unknown() : this();

  /// Loading state
  const AuthState.loading() : this(status: AuthStatus.unknown, isLoading: true);

  /// Authenticated state
  const AuthState.authenticated(UserEntity user)
    : this(status: AuthStatus.authenticated, user: user, isLoading: false);

  /// Unauthenticated state
  const AuthState.unauthenticated()
    : this(status: AuthStatus.unauthenticated, isLoading: false);

  /// Error state
  const AuthState.error(String message)
    : this(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
        isLoading: false,
      );

  /// Password reset sent state
  const AuthState.passwordResetSent()
    : this(
        status: AuthStatus.unauthenticated,
        passwordResetSent: true,
        isLoading: false,
      );

  /// Check if user is admin
  bool get isAdmin => user?.isAdmin ?? false;

  /// Check if user is student
  bool get isStudent => user?.isStudent ?? false;

  /// Copy with updated fields
  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool? passwordResetSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      passwordResetSent: passwordResetSent ?? false,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    isLoading,
    errorMessage,
    passwordResetSent,
  ];
}
