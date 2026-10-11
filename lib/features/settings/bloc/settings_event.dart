import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class ToggleThemeEvent extends SettingsEvent {
  final bool isDarkMode;

  const ToggleThemeEvent({required this.isDarkMode});

  @override
  List<Object?> get props => [isDarkMode];
}
