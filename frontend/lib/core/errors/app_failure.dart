enum FailureKind {
  validation,
  notFound,
  permission,
  conflict,
  network,
  timeout,
  unexpected,
}

class AppFailure implements Exception {
  final FailureKind kind;
  final String message;
  final Object? cause;

  const AppFailure({required this.kind, required this.message, this.cause});

  const AppFailure.validation(String message, {Object? cause})
    : this(kind: FailureKind.validation, message: message, cause: cause);

  const AppFailure.notFound(String message, {Object? cause})
    : this(kind: FailureKind.notFound, message: message, cause: cause);

  const AppFailure.permission(String message, {Object? cause})
    : this(kind: FailureKind.permission, message: message, cause: cause);

  const AppFailure.conflict(String message, {Object? cause})
    : this(kind: FailureKind.conflict, message: message, cause: cause);

  const AppFailure.network(String message, {Object? cause})
    : this(kind: FailureKind.network, message: message, cause: cause);

  const AppFailure.timeout(String message, {Object? cause})
    : this(kind: FailureKind.timeout, message: message, cause: cause);

  const AppFailure.unexpected(String message, {Object? cause})
    : this(kind: FailureKind.unexpected, message: message, cause: cause);

  @override
  String toString() => message;
}
