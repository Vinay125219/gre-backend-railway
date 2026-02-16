// Custom exceptions for data layer
// These get caught and converted to Failures in repositories

class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException({this.message = 'Server error occurred', this.code});

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({this.message = 'Authentication error', this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error occurred'});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Network error occurred'});

  @override
  String toString() => 'NetworkException: $message';
}

class NotFoundException implements Exception {
  final String message;

  const NotFoundException({this.message = 'Resource not found'});

  @override
  String toString() => 'NotFoundException: $message';
}

class PermissionException implements Exception {
  final String message;

  const PermissionException({this.message = 'Permission denied'});

  @override
  String toString() => 'PermissionException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  const ValidationException({
    this.message = 'Validation error',
    this.fieldErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}
