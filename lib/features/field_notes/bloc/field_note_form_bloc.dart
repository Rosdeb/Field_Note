import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/customer.dart';
import '../../../models/field_note.dart';
import '../../../models/site.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/field_note_repository.dart';
import '../../../repositories/site_repository.dart';
import 'field_note_form_event.dart';
import 'field_note_form_state.dart';

export 'field_note_form_event.dart';
export 'field_note_form_state.dart';

class FieldNoteFormBloc extends Bloc<FieldNoteFormEvent, FieldNoteFormState> {
  final CustomerRepository customerRepository;
  final SiteRepository siteRepository;
  final FieldNoteRepository fieldNoteRepository;

  FieldNoteFormBloc({
    required this.customerRepository,
    required this.siteRepository,
    required this.fieldNoteRepository,
  }) : super(const FieldNoteFormState()) {
    on<LoadFieldNoteForm>(_load);
    on<SelectNoteCustomer>((event, emit) {
      if (state.customers.any((customer) => customer.id == event.customerId)) {
        emit(state.copyWith(customerId: event.customerId));
      }
    });
    on<SelectNoteSite>((event, emit) {
      if (state.sites.any((site) => site.id == event.siteId)) {
        emit(state.copyWith(siteId: event.siteId));
      }
    });
    on<SelectNoteStatus>(
      (event, emit) => emit(state.copyWith(status: event.status)),
    );
    on<SubmitFieldNoteForm>(_save);
  }

  Future<void> _load(
    LoadFieldNoteForm event,
    Emitter<FieldNoteFormState> emit,
  ) async {
    try {
      final loadedCustomers = await customerRepository.getCustomers();
      final loadedSites = await siteRepository.getSites();
      final note = event.noteId == null
          ? null
          : await fieldNoteRepository.getFieldNoteById(event.noteId!);
      // Dropdown selections must match exactly one non-empty item ID.
      final customers = <String, Customer>{
        for (final customer in loadedCustomers)
          if (customer.id.isNotEmpty) customer.id: customer,
      }.values.toList();
      final sites = <String, Site>{
        for (final site in loadedSites)
          if (site.id.isNotEmpty) site.id: site,
      }.values.toList();
      final siteId = note?.siteId ?? (sites.isEmpty ? null : sites.first.id);
      final matchingSites = sites.where((site) => site.id == siteId);
      final selectedSite = matchingSites.isEmpty ? null : matchingSites.first;
      // Server notes may omit customerId; use their site's customer when possible.
      final customerId = note == null
          ? (customers.isEmpty ? null : customers.first.id)
          : (note.customerId.isEmpty
                ? selectedSite?.customerId
                : note.customerId);
      emit(
        FieldNoteFormState(
          customers: customers,
          sites: sites,
          customerId: customers.any((customer) => customer.id == customerId)
              ? customerId
              : null,
          siteId: selectedSite?.id,
          existingNote: note,
          status: note?.status ?? 'OPEN',
          isLoading: false,
        ),
      );
    } catch (error) {
      emit(FieldNoteFormState(isLoading: false, error: error.toString()));
    }
  }

  Future<void> _save(
    SubmitFieldNoteForm event,
    Emitter<FieldNoteFormState> emit,
  ) async {
    if (state.isLoading || state.isSaving || state.isSaved) return;
    if (event.title.trim().isEmpty) {
      emit(state.copyWith(error: 'Note title is required'));
      return;
    }
    if (state.siteId == null) {
      emit(state.copyWith(error: 'Please select a site before saving.'));
      return;
    }
    final existing = state.existingNote;
    final note = existing == null
        ? FieldNote(
            id: '',
            siteId: state.siteId!,
            customerId: state.customerId ?? '',
            title: event.title.trim(),
            notes: event.notes.trim(),
            status: state.status,
            createdAt: DateTime.now(),
          )
        : existing.copyWith(
            siteId: state.siteId,
            customerId: state.customerId ?? '',
            title: event.title.trim(),
            notes: event.notes.trim(),
            description: event.notes.trim(),
            status: state.status,
          );
    emit(state.copyWith(isSaving: true));
    try {
      await fieldNoteRepository.saveFieldNote(note);
      emit(state.copyWith(isSaving: false, isSaved: true));
    } catch (error) {
      emit(state.copyWith(isSaving: false, error: error.toString()));
    }
  }
}
