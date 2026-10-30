import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/session_notifier.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final SessionNotifier _sessionNotifier;

  AuthController({
    required AuthRepository authRepository,
    required SessionNotifier sessionNotifier,
  })  : _authRepository = authRepository,
        _sessionNotifier = sessionNotifier,
        super(const AuthState.initial()) {
    _init();
  }

  void _init() {
    _sessionNotifier.addListener(_handleSessionExpired);
    checkAuthStatus();
  }

  void _handleSessionExpired() {
    state = const AuthState.unauthenticated(
      errorMessage: 'Your session has expired. Please log in again.',
    );
  }

  Future<void> checkAuthStatus() async {
    final isAuth = await _authRepository.isAuthenticated();
    if (isAuth) {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
        return;
      }
    }
    state = const AuthState.unauthenticated();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      final user = await _authRepository.login(
        username: username,
        password: password,
      );
      state = AuthState.authenticated(user);
      return true;
    } on Failure catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('An unexpected error occurred: $e');
      return false;
    }
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    await _authRepository.logout();
    state = const AuthState.unauthenticated();
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState.unauthenticated();
    }
  }

  @override
  void dispose() {
    _sessionNotifier.removeListener(_handleSessionExpired);
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final sessionNotifier = ref.watch(sessionNotifierProvider);
  return AuthController(
    authRepository: authRepository,
    sessionNotifier: sessionNotifier,
  );
});
