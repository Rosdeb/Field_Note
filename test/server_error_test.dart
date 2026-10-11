import 'package:dio/dio.dart';
import 'package:field_notes/core/network/exceptions/app_exception.dart';
import 'package:field_notes/features/auth/bloc/auth_bloc.dart';
import 'package:field_notes/features/auth/screens/login_screen.dart';
import 'package:field_notes/models/user.dart';
import 'package:field_notes/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingAuthRepository implements AuthRepository {
  Object failure = DioException(
    requestOptions: RequestOptions(path: '/api/auth/login'),
    type: DioExceptionType.connectionError,
    error: const NetworkException(),
  );
  int attempts = 0;

  @override
  Future<User?> login(String email, String password) async {
    attempts++;
    throw failure;
  }

  @override
  Future<User?> register(String email, String password) =>
      login(email, password);
  @override
  User? getCurrentUser() => null;
  @override
  bool get isAuthenticated => false;
  @override
  Future<void> logout() async {}
  @override
  Future<Session?> refreshToken() async => null;
}

void main() {
  testWidgets('Unavailable server supports retry and preserves login fields', (
    tester,
  ) async {
    final repository = FailingAuthRepository();
    final bloc = AuthBloc(authRepository: repository);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const LoginScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'long-password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Server unavailable'), findsOneWidget);
    expect(find.textContaining('Changes saved locally'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repository.attempts, 2);
    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Server unavailable'), findsNothing);
  });

  test('Credential errors do not show server-unavailable page', () async {
    final repository = FailingAuthRepository()
      ..failure = const UnauthorizedException(message: 'Invalid credentials');
    final bloc = AuthBloc(authRepository: repository);
    final result = bloc.stream.firstWhere((state) => state is AuthFailure);
    bloc.add(
      const AuthLoginRequested(
        email: 'user@example.com',
        password: 'long-password',
      ),
    );
    final state = await result as AuthFailure;
    expect(state.serverUnavailable, isFalse);
    expect(state.message, 'Invalid credentials');
    await bloc.close();
  });
}
