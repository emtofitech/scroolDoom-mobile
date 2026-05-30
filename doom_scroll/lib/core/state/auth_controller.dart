import 'package:doom_scroll/core/services/auth_service.dart';
import 'package:doom_scroll/core/services/token_storage.dart';
import 'package:doom_scroll/core/state/auth_state.dart';
import 'package:flutter_riverpod/legacy.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState());

  /// APP START
  Future<void> init() async {
    final token = await TokenStorage.accessToken;

    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.guest);
    } else {
      state = state.copyWith(status: AuthStatus.authenticated);
      
      // Perform background sliding refresh to keep the session active
      final refreshResult = await AuthService.slidingRefresh();
      if (!refreshResult.isSuccess) {
        // If refresh failed because the token was cleared (e.g. 401/expired),
        // revert user state to guest/unauthenticated.
        final currentToken = await TokenStorage.accessToken;
        if (currentToken == null || currentToken.isEmpty) {
          state = state.copyWith(status: AuthStatus.guest);
        }
      }
    }
  }

  /// REGISTER
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.register(
      username: username,
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  /// LOGIN
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await AuthService.login(email: email, password: password);

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await AuthService.logout();

    state = state.copyWith(status: AuthStatus.guest);
  }

  /// PROTECTED ACTIONS
  void requireAuth(Function() onContinue) {
    if (state.isAuthenticated) {
      onContinue();
    }
  }
}
