enum AuthFailureCode {
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  emailAlreadyInUseGoogle,
  emailAlreadyInUseProvider,
  weakPassword,
  invalidEmail,
  invalidCredential,
  accountExistsWithDifferentCredential,
  googleAborted,
  network,
  unknown,
}

class AuthFailure implements Exception {
  final AuthFailureCode code;
  final String? message;

  const AuthFailure({required this.code, this.message});

  @override
  String toString() {
    return 'AuthFailure(code: $code, message: $message)';
  }
}
