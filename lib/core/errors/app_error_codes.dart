/**
 * Structured Application Error Codes and Exceptions
 * Author: Eng. MHD. Shadi AL-Hasan <mhd.shadi.alhasan@gmail.com>
 * Phone: +963934005922
 * Copyright (c) 2026 MHD. Shadi AL-Hasan
 */

enum AppErrorCode {
  // Authentication & Authorization
  AUTH_UNAUTHORIZED(
      'AUTH_001', 'Authentication credentials missing or invalid'),
  AUTH_FORBIDDEN('AUTH_002', 'Insufficient permissions to access resource'),
  AUTH_TOKEN_EXPIRED('AUTH_003', 'Authentication token has expired'),

  // Network & Routing
  NETWORK_OFFLINE('NET_001', 'Device is offline or unreachable'),
  HTTP_TIMEOUT('NET_002', 'Network request timed out'),
  ROUTE_NOT_FOUND('ROUTE_404', 'Target HTTP route or endpoint not found'),
  METHOD_NOT_ALLOWED('ROUTE_405', 'HTTP method is not allowed on this route'),

  // Server & Internal
  SERVER_INTERNAL_ERROR('SRV_500', 'Internal server encountered an error'),
  BAD_GATEWAY('SRV_502', 'Bad gateway or edge communication failure'),

  // Sync & Persistence
  SYNC_QUEUE_PERSISTENCE_FAILED(
      'SYNC_001', 'Failed to persist sync queue snapshot to disk'),
  SYNC_ITEM_CORRUPTED(
      'SYNC_002', 'Sync queue item contains corrupted or unparseable data'),
  SYNC_CONCURRENCY_CONFLICT(
      'SYNC_003', 'Version conflict detected during sync execution'),

  // Validation & State
  VALIDATION_ERROR('VAL_001', 'Input parameter or payload failed validation'),
  INVALID_STATE_TRANSITION(
      'STATE_001', 'Attempted invalid state machine transition');

  final String code;
  final String description;

  const AppErrorCode(this.code, this.description);

  @override
  String toString() => '$code: $description';
}

class AppException implements Exception {
  final AppErrorCode code;
  final String message;
  final dynamic details;
  final DateTime timestamp;

  AppException({
    required this.code,
    String? message,
    this.details,
    DateTime? timestamp,
  })  : message = message ?? code.description,
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'code': code.code,
        'name': code.name,
        'message': message,
        'details': details?.toString(),
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'AppException(code: ${code.code}, message: "$message")';
}

class AppFailure {
  final AppErrorCode code;
  final String message;
  final dynamic cause;

  const AppFailure({
    required this.code,
    required this.message,
    this.cause,
  });

  factory AppFailure.fromException(AppException ex) {
    return AppFailure(
      code: ex.code,
      message: ex.message,
      cause: ex.details,
    );
  }

  @override
  String toString() => 'AppFailure(code: ${code.code}, message: $message)';
}
