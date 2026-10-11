import 'package:equatable/equatable.dart';
import '../../../models/site.dart';

abstract class SiteEvent extends Equatable {
  const SiteEvent();

  @override
  List<Object?> get props => [];
}

class LoadSites extends SiteEvent {
  final String? customerId;
  final String? query;

  const LoadSites({this.customerId, this.query});

  @override
  List<Object?> get props => [customerId, query];
}

class SaveSiteEvent extends SiteEvent {
  final Site site;

  const SaveSiteEvent({required this.site});

  @override
  List<Object?> get props => [site];
}

class DeleteSiteEvent extends SiteEvent {
  final String id;

  const DeleteSiteEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
