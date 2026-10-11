import 'package:flutter/material.dart';
import 'app_button.dart';

class ServerErrorPage extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final bool isLoading;
  final String backText;

  const ServerErrorPage({
    super.key,
    required this.onRetry,
    required this.onBack,
    this.isLoading = false,
    this.backText = 'Go back',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Server unavailable',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to reach the server. Please try again.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    text: 'Retry',
                    icon: Icons.refresh_rounded,
                    isLoading: isLoading,
                    onPressed: onRetry,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: backText,
                    variant: AppButtonVariant.text,
                    onPressed: isLoading ? null : onBack,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
