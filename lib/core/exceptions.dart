/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Exception thrown by repository operations
class RepositoryException extends AppException {
  RepositoryException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown during form validation
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required super.message,
    this.fieldErrors,
    super.code,
    super.stackTrace,
  });
}

/// Exception thrown for network-related errors
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for authentication-related errors
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for not found errors (404)
class NotFoundException extends AppException {
  NotFoundException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when access is denied (403)
class AccessDeniedException extends AppException {
  AccessDeniedException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for server errors (500+)
class ServerException extends AppException {
  ServerException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for timeout errors
class TimeoutException extends AppException {
  TimeoutException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when QR scan fails
class ScanException extends AppException {
  ScanException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown when student is not found
class StudentNotFoundException extends AppException {
  final String? nis;

  StudentNotFoundException({
    required super.message,
    this.nis,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Exception thrown for attendance-related errors
class AttendanceException extends AppException {
  AttendanceException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}
