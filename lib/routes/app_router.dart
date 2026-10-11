import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/customers/screens/customer_details_screen.dart';
import '../features/customers/screens/customer_form_screen.dart';
import '../features/customers/screens/customers_screen.dart';
import '../features/field_notes/screens/field_note_details_screen.dart';
import '../features/field_notes/screens/field_note_form_screen.dart';
import '../features/field_notes/screens/field_notes_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/sites/screens/site_details_screen.dart';
import '../features/sites/screens/site_form_screen.dart';
import '../features/sites/screens/sites_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/sync/screens/sync_screen.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String customers = '/customers';
  static const String customerDetails = '/customers/details';
  static const String customerForm = '/customers/form';
  static const String sites = '/sites';
  static const String siteDetails = '/sites/details';
  static const String siteForm = '/sites/form';
  static const String fieldNotes = '/field-notes';
  static const String fieldNoteDetails = '/field-notes/details';
  static const String fieldNoteForm = '/field-notes/form';
  static const String sync = '/sync';
  static const String settings = '/settings';

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static CustomTransitionPage<void> _buildCustomTransitionPage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration transitionDuration = const Duration(milliseconds: 350),
    Duration reverseTransitionDuration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: onboarding,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: home,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: login,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: register,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: customers,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const CustomersScreen(),
        ),
        routes: [
          GoRoute(
            path: 'form',
            pageBuilder: (context, state) {
              final customerId = state.extra as String?;
              return _buildCustomTransitionPage(
                context: context,
                state: state,
                child: CustomerFormScreen(customerId: customerId),
              );
            },
          ),
          GoRoute(
            path: 'details',
            pageBuilder: (context, state) {
              final customerId = state.extra as String? ?? '';
              return _buildCustomTransitionPage(
                context: context,
                state: state,
                child: CustomerDetailsScreen(customerId: customerId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: sites,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const SitesScreen(),
        ),
        routes: [
          GoRoute(
            path: 'form',
            pageBuilder: (context, state) {
              final siteId = state.extra as String?;
              return _buildCustomTransitionPage(
                context: context,
                state: state,
                child: SiteFormScreen(siteId: siteId),
              );
            },
          ),
          GoRoute(
            path: 'details',
            pageBuilder: (context, state) {
              final siteId = state.extra as String? ?? '';
              return _buildCustomTransitionPage(
                context: context,
                state: state,
                child: SiteDetailsScreen(siteId: siteId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: fieldNotes,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const FieldNotesScreen(),
        ),
        routes: [
          GoRoute(
            path: 'form',
            pageBuilder: (context, state) {
              final noteId = state.extra as String?;
              return _buildCustomTransitionPage(
                context: context,
                state: state,
                child: FieldNoteFormScreen(noteId: noteId),
              );
            },
          ),
          GoRoute(
            path: 'details',
            pageBuilder: (context, state) {
              final noteId = state.extra as String? ?? '';
              return _buildCustomTransitionPage(
                context: context,
                state: state,
                child: FieldNoteDetailsScreen(noteId: noteId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: sync,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const SyncScreen(),
        ),
      ),
      GoRoute(
        path: settings,
        pageBuilder: (context, state) => _buildCustomTransitionPage(
          context: context,
          state: state,
          child: const SettingsScreen(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => _buildCustomTransitionPage(
      context: context,
      state: state,
      child: Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text('No route defined for ${state.uri}'),
        ),
      ),
    ),
  );
}
