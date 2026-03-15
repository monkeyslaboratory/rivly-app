import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/secure_storage.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository = AuthRepository();
  final SecureStorageService _storage = SecureStorageService();

  AuthCubit() : super(AuthInitial());

  Future<void> checkAuth() async {
    emit(AuthLoading());
    try {
      final hasTokens = await _storage.hasTokens();
      if (!hasTokens) {
        emit(Unauthenticated());
        return;
      }

      final user = await _authRepository.getMe();
      emit(Authenticated(user));
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await _authRepository.refreshToken();
        if (refreshed) {
          try {
            final user = await _authRepository.getMe();
            emit(Authenticated(user));
            return;
          } catch (_) {
            // Fall through to unauthenticated
          }
        }
      }
      await _storage.clearTokens();
      emit(Unauthenticated());
    } catch (_) {
      await _storage.clearTokens();
      emit(Unauthenticated());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
      emit(Authenticated(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred'));
    }
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(
        email: email,
        username: username,
        password: password,
      );
      emit(Authenticated(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred'));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
