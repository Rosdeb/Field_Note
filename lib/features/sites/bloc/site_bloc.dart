import 'package:flutter_bloc/flutter_bloc.dart';
import 'site_event.dart';
import 'site_state.dart';
import '../../../repositories/site_repository.dart';

export 'site_event.dart';
export 'site_state.dart';

class SiteBloc extends Bloc<SiteEvent, SiteState> {
  final SiteRepository siteRepository;

  SiteBloc({required this.siteRepository}) : super(SiteInitial()) {
    on<LoadSites>(_onLoadSites);
    on<SaveSiteEvent>(_onSaveSite);
    on<DeleteSiteEvent>(_onDeleteSite);
  }

  Future<void> _onLoadSites(
    LoadSites event,
    Emitter<SiteState> emit,
  ) async {
    emit(SiteLoading());
    try {
      final sites = await siteRepository.getSites(
        customerId: event.customerId,
        query: event.query,
      );
      emit(SiteLoaded(
        sites: sites,
        customerId: event.customerId,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(SiteError(message: e.toString()));
    }
  }

  Future<void> _onSaveSite(
    SaveSiteEvent event,
    Emitter<SiteState> emit,
  ) async {
    try {
      await siteRepository.saveSite(event.site);
      emit(const SiteActionSuccess(message: 'Site saved successfully'));
      final sites = await siteRepository.getSites(customerId: event.site.customerId);
      emit(SiteLoaded(sites: sites, customerId: event.site.customerId));
    } catch (e) {
      emit(SiteError(message: e.toString()));
    }
  }

  Future<void> _onDeleteSite(
    DeleteSiteEvent event,
    Emitter<SiteState> emit,
  ) async {
    try {
      await siteRepository.deleteSite(event.id);
      emit(const SiteActionSuccess(message: 'Site deleted successfully'));
      final sites = await siteRepository.getSites();
      emit(SiteLoaded(sites: sites));
    } catch (e) {
      emit(SiteError(message: e.toString()));
    }
  }
}
