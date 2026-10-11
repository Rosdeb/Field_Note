import 'package:equatable/equatable.dart';

enum SplashNavigationTarget {
  onboarding,
  login,
  home,
}

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashNavigate extends SplashState {
  final SplashNavigationTarget target;

  const SplashNavigate(this.target);

  @override
  List<Object?> get props => [target];
}
