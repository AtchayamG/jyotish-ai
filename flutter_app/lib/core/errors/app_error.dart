// lib/core/errors/app_error.dart
class AppError implements Exception {
  final String message;
  final String type;
  final int? statusCode;

  const AppError._({required this.type, required this.message, this.statusCode});

  const factory AppError.network(String msg)            = _NetworkError;
  const factory AppError.unauthorized(String msg)       = _UnauthorizedError;
  const factory AppError.notFound(String msg)           = _NotFoundError;
  const factory AppError.conflict(String msg)           = _ConflictError;
  const factory AppError.validation(String msg)         = _ValidationError;
  const factory AppError.server(String msg, int code)   = _ServerError;
  const factory AppError.cancelled(String msg)          = _CancelledError;
  const factory AppError.unknown(String msg)            = _UnknownError;

  bool get isUnauthorized => type == "unauthorized";
  bool get isNetwork      => type == "network";

  @override String toString() => "AppError[$type]: $message";
}

class _NetworkError      extends AppError { const _NetworkError(String m)       : super._(type: "network",      message: m); }
class _UnauthorizedError extends AppError { const _UnauthorizedError(String m)  : super._(type: "unauthorized", message: m); }
class _NotFoundError     extends AppError { const _NotFoundError(String m)      : super._(type: "not_found",    message: m); }
class _ConflictError     extends AppError { const _ConflictError(String m)      : super._(type: "conflict",     message: m); }
class _ValidationError   extends AppError { const _ValidationError(String m)    : super._(type: "validation",   message: m); }
class _ServerError       extends AppError { const _ServerError(String m, int c) : super._(type: "server",       message: m, statusCode: c); }
class _CancelledError    extends AppError { const _CancelledError(String m)     : super._(type: "cancelled",    message: m); }
class _UnknownError      extends AppError { const _UnknownError(String m)       : super._(type: "unknown",      message: m); }
