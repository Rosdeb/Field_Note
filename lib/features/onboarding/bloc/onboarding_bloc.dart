import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/hive_service.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

export 'onboarding_event.dart';
export 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final HiveService hiveService;

  static const List<OnboardingItem> defaultItems = [
    OnboardingItem(
      title: 'Site Inspections Made Easy',
      subtitle:
          'Create field notes on the spot with photos, geolocation data, and comprehensive inspection observations.',
      icon: 'assets/icons/writing.png',
      isAsset: true,
    ),
    OnboardingItem(
      title: 'Works Fully Offline',
      subtitle:
          'No signal on site? No problem! Continue creating notes, client logs, and site updates seamlessly offline.',
      icon: 'assets/icons/server.png',
      isAsset: true,
    ),
    OnboardingItem(
      title: 'Automatic Cloud Sync',
      subtitle:
          'When connection is restored, all your queued inspections sync securely to your company dashboard.',
      icon: 'assets/icons/stats.png',
      isAsset: true,
    ),
  ];

  OnboardingBloc({required this.hiveService})
      : super(
          const OnboardingState(
            currentPage: 0,
            totalPages: 3,
            items: defaultItems,
            isCompleted: false,
          ),
        ) {
    on<OnboardingPageChanged>(_onPageChanged);
    on<OnboardingNextClicked>(_onNextClicked);
    on<OnboardingSkipClicked>(_onSkipClicked);
    on<OnboardingCompletedEvent>(_onCompleted);
  }

  void _onPageChanged(
    OnboardingPageChanged event,
    Emitter<OnboardingState> emit,
  ) {
    if (event.pageIndex >= 0 && event.pageIndex < state.totalPages) {
      emit(state.copyWith(currentPage: event.pageIndex));
    }
  }

  void _onNextClicked(
    OnboardingNextClicked event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.currentPage < state.totalPages - 1) {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    } else {
      add(OnboardingCompletedEvent());
    }
  }

  void _onSkipClicked(
    OnboardingSkipClicked event,
    Emitter<OnboardingState> emit,
  ) {
    add(OnboardingCompletedEvent());
  }

  Future<void> _onCompleted(
    OnboardingCompletedEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    await hiveService.setOnboardingCompleted(true);
    emit(state.copyWith(isCompleted: true));
  }
}
