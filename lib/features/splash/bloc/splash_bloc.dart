import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/hive_service.dart';
import '../../../repositories/auth_repository.dart';
import 'splash_event.dart';
import 'splash_state.dart';

export 'splash_event.dart';
export 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final AuthRepository authRepository;
  final HiveService hiveService;

  SplashBloc({
    required this.authRepository,
    required this.hiveService,
  }) : super(SplashInitial()) {
    on<SplashAppStarted>(_onAppStarted);
  }

  Future<void> _onAppStarted(
    SplashAppStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());

    // Allow a smooth branded splash animation duration
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    final isOnboardingCompleted = hiveService.isOnboardingCompleted();
    if (!isOnboardingCompleted) {
      emit(const SplashNavigate(SplashNavigationTarget.onboarding));
      return;
    }

    final isAuthenticated =
        authRepository.isAuthenticated && authRepository.getCurrentUser() != null;
    if (isAuthenticated) {
      emit(const SplashNavigate(SplashNavigationTarget.home));
    } else {
      emit(const SplashNavigate(SplashNavigationTarget.login));
    }
  }
}
