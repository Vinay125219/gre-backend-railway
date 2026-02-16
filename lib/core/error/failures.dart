import 'package:equatable/equatable.dart';

/// Base failure class for domain layer error handling
/// Used with `Either<Failure, T>` for functional error handling
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server-side failures (Firebase, API)
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'A server error occurred. Please try again.',
    super.code,
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed. Please try again.',
    super.code,
  });

  // Common auth failure types
  factory AuthFailure.invalidCredentials() => const AuthFailure(
    message: 'Invalid email or password.',
    code: 'invalid-credentials',
  );

  factory AuthFailure.userNotFound() => const AuthFailure(
    message: 'No account found with this email.',
    code: 'user-not-found',
  );

  factory AuthFailure.emailAlreadyInUse() => const AuthFailure(
    message: 'An account already exists with this email.',
    code: 'email-already-in-use',
  );

  factory AuthFailure.weakPassword() => const AuthFailure(
    message: 'Password is too weak. Please use a stronger password.',
    code: 'weak-password',
  );

  factory AuthFailure.sessionExpired() => const AuthFailure(
    message: 'Your session has expired. Please log in again.',
    code: 'session-expired',
  );

  factory AuthFailure.unauthorized() => const AuthFailure(
    message: 'You are not authorized to perform this action.',
    code: 'unauthorized',
  );
}

/// Network/connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'no-connection',
  });
}

/// Cache/local storage failures
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to access local data.',
    super.code = 'cache-error',
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'validation-error',
  });
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
    super.code = 'not-found',
  });
}

/// Permission/access failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'You do not have permission to access this resource.',
    super.code = 'permission-denied',
  });
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'unknown-error',
  });
}
