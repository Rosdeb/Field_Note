import 'package:dio/dio.dart';
import '../../../core/network/exceptions/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../repositories/auth_repository.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  void _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) {
    final user = authRepository.getCurrentUser();
    if (user != null && authRepository.isAuthenticated) {
      emit(Authenticated(user: user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(
          const AuthFailure(message: 'Invalid credentials. Please try again.'),
        );
      }
    } catch (e) {
      emit(_failureFor(e));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(event.email, event.password);
      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(
          const AuthFailure(
            message: 'Registration failed. Email might already exist.',
          ),
        );
      }
    } catch (e) {
      emit(_failureFor(e));
    }
  }

  AuthFailure _failureFor(Object error) {
    final cause = error is DioException ? error.error : error;
    final unavailable =
        cause is NetworkException ||
        cause is TimeoutException ||
        (cause is ServerException && (cause.statusCode ?? 500) >= 500);
    return AuthFailure(
      message: unavailable
          ? 'Unable to reach the server. Please try again.'
          : cause.toString().replaceAll('Exception: ', ''),
      serverUnavailable: unavailable,
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await authRepository.logout();
    emit(Unauthenticated());
  }
}
