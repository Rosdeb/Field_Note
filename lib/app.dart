import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/service_locator.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/customers/bloc/customer_bloc.dart';
import 'features/field_notes/bloc/field_note_bloc.dart';
import 'features/settings/bloc/settings_bloc.dart';
import 'features/sites/bloc/site_bloc.dart';
import 'features/sync/bloc/sync_bloc.dart';
import 'routes/app_router.dart';

class FieldNotesApp extends StatelessWidget {
  const FieldNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final services = ServiceLocator();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) =>
              AuthBloc(authRepository: services.authRepository)
                ..add(AuthCheckRequested()),
        ),
        BlocProvider<CustomerBloc>(
          create: (_) =>
              CustomerBloc(customerRepository: services.customerRepository)
                ..add(const LoadCustomers()),
        ),
        BlocProvider<SiteBloc>(
          create: (_) =>
              SiteBloc(siteRepository: services.siteRepository)
                ..add(const LoadSites()),
        ),
        BlocProvider<FieldNoteBloc>(
          create: (_) =>
              FieldNoteBloc(fieldNoteRepository: services.fieldNoteRepository)
                ..add(const LoadFieldNotes()),
        ),
        BlocProvider<SyncBloc>(
          create: (_) => SyncBloc(
            syncRepository: services.syncRepository,
            syncManager: services.syncManager,
          )..add(LoadSyncStatus()),
        ),
        BlocProvider<SettingsBloc>(create: (_) => SettingsBloc()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'Field Notes',
            debugShowCheckedModeBanner: false,
            themeMode: settingsState.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.white,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
