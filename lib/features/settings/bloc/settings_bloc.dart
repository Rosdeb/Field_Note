import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_event.dart';
import 'settings_state.dart';

export 'settings_event.dart';
export 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<ToggleThemeEvent>(_onToggleTheme);
  }

  void _onToggleTheme(
    ToggleThemeEvent event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(isDarkMode: event.isDarkMode));
  }
}
