import 'package:equatable/equatable.dart';

class OnboardingItem extends Equatable {
  final String title;
  final String subtitle;
  final String icon;
  final bool isAsset;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isAsset = false,
  });

  @override
  List<Object?> get props => [title, subtitle, icon, isAsset];
}

class OnboardingState extends Equatable {
  final int currentPage;
  final int totalPages;
  final List<OnboardingItem> items;
  final bool isCompleted;

  const OnboardingState({
    this.currentPage = 0,
    this.totalPages = 3,
    this.items = const [],
    this.isCompleted = false,
  });

  bool get isLastPage => currentPage == totalPages - 1;

  OnboardingState copyWith({
    int? currentPage,
    int? totalPages,
    List<OnboardingItem>? items,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      items: items ?? this.items,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [currentPage, totalPages, items, isCompleted];
}
