import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/customer.dart';
import '../../../models/site.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/site_repository.dart';
import 'site_form_event.dart';
import 'site_form_state.dart';

export 'site_form_event.dart';
export 'site_form_state.dart';

class SiteFormBloc extends Bloc<SiteFormEvent, SiteFormState> {
  final CustomerRepository customerRepository;
  final SiteRepository siteRepository;
  String? _editingSiteId;

  SiteFormBloc({required this.customerRepository, required this.siteRepository})
    : super(const SiteFormState()) {
    on<LoadSiteForm>(_load);
    on<SelectSiteCustomer>((event, emit) {
      if (state.customers.any((customer) => customer.id == event.customerId)) {
        emit(state.copyWith(customerId: event.customerId));
      }
    });
    on<SearchSiteCustomers>(
      (event, emit) => emit(state.copyWith(query: event.query)),
    );
    on<SubmitSiteForm>(_save);
  }

  Future<void> _load(LoadSiteForm event, Emitter<SiteFormState> emit) async {
    _editingSiteId = event.siteId;
    try {
      final loadedCustomers = await customerRepository.getCustomers();
      final site = event.siteId == null
          ? null
          : await siteRepository.getSiteById(event.siteId!);
      if (event.siteId != null && site == null) {
        emit(
          const SiteFormState(
            isLoading: false,
            error: 'This site could not be found.',
          ),
        );
        return;
      }
      final customers =
          <String, Customer>{
            for (final customer in loadedCustomers)
              if (customer.id.isNotEmpty) customer.id: customer,
          }.values.toList()..sort(
            (first, second) =>
                first.name.toLowerCase().compareTo(second.name.toLowerCase()),
          );
      final customerId = state.customerId ?? site?.customerId;
      emit(
        SiteFormState(
          customers: customers,
          existingSite: site,
          customerId: customers.any((customer) => customer.id == customerId)
              ? customerId
              : null,
          isLoading: false,
        ),
      );
    } catch (error) {
      emit(SiteFormState(isLoading: false, error: error.toString()));
    }
  }

  Future<void> _save(SubmitSiteForm event, Emitter<SiteFormState> emit) async {
    if (state.isLoading || state.isSaving || state.isSaved) return;
    if (_editingSiteId != null && state.existingSite == null) {
      emit(
        state.copyWith(
          error: 'This site could not be loaded. Please reopen the form.',
        ),
      );
      return;
    }
    if (event.name.trim().isEmpty) {
      emit(state.copyWith(error: 'Site name is required'));
      return;
    }
    if (state.selectedCustomer == null) {
      emit(state.copyWith(error: 'Please select a customer.'));
      return;
    }
    final existing = state.existingSite;
    final site = existing == null
        ? Site(
            id: '',
            customerId: state.customerId!,
            name: event.name.trim(),
            address: event.address.trim(),
          )
        : existing.copyWith(
            customerId: state.customerId,
            name: event.name.trim(),
            address: event.address.trim(),
          );
    emit(state.copyWith(isSaving: true));
    try {
      await siteRepository.saveSite(site);
      emit(state.copyWith(isSaving: false, isSaved: true));
    } catch (error) {
      emit(state.copyWith(isSaving: false, error: error.toString()));
    }
  }
}
