import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showServerError = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      FloatingErrorBar.show(
        context,
        message: 'Please enter both email and password.',
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      FloatingErrorBar.show(
        context,
        message: 'Please enter a valid email address.',
      );
      return;
    }

    if (password.length < 6) {
      FloatingErrorBar.show(
        context,
        message: 'Password must be at least 6 characters.',
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginRequested(email: email, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          FloatingSuccessBar.show(context, message: 'Welcome back!');
          context.go(AppRouter.home);
        } else if (state is AuthFailure) {
          if (state.serverUnavailable) {
            setState(() => _showServerError = true);
          } else {
            setState(() => _showServerError = false);
            FloatingErrorBar.show(context, message: state.message);
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        if (_showServerError) {
          return ServerErrorPage(
            isLoading: isLoading,
            onRetry: _handleLogin,
            onBack: () => setState(() => _showServerError = false),
            backText: 'Back to login',
          );
        }

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Image.asset(
                        'assets/images/Field_Note_Icon.png',
                        height: 64,
                        width: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Field Notes',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to sync your inspection notes',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _emailController,
                    title: 'Email',
                    hint: 'name@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    title: 'Password',
                    hint: 'At least 10 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Login',
                    isLoading: isLoading,
                    icon: Icons.login,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: "Don't have an account? Register",
                    variant: AppButtonVariant.text,
                    onPressed: () => context.push(AppRouter.register),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
