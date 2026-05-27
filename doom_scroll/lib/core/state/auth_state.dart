enum AuthStatus { unknown, guest, authenticated }

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? error;

  AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.error,
  });

  bool get isGuest => status == AuthStatus.guest;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, bool? isLoading, String? error}) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
