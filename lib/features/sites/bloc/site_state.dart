import 'package:equatable/equatable.dart';
import '../../../models/site.dart';

abstract class SiteState extends Equatable {
  const SiteState();

  @override
  List<Object?> get props => [];
}

class SiteInitial extends SiteState {}

class SiteLoading extends SiteState {}

class SiteLoaded extends SiteState {
  final List<Site> sites;
  final String? customerId;
  final String? searchQuery;

  const SiteLoaded({
    required this.sites,
    this.customerId,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [sites, customerId, searchQuery];
}

class SiteActionSuccess extends SiteState {
  final String message;

  const SiteActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class SiteError extends SiteState {
  final String message;

  const SiteError({required this.message});

  @override
  List<Object?> get props => [message];
}
