import 'package:equatable/equatable.dart';
import '../../../models/customer.dart';
import '../../../models/field_note.dart';
import '../../../models/site.dart';

class FieldNoteFormState extends Equatable {
  final List<Customer> customers;
  final List<Site> sites;
  final String? customerId;
  final String? siteId;
  final String status;
  final FieldNote? existingNote;
  final bool isLoading;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const FieldNoteFormState({
    this.customers = const [],
    this.sites = const [],
    this.customerId,
    this.siteId,
    this.status = 'OPEN',
    this.existingNote,
    this.isLoading = true,
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });

  // Selections passed here are non-null; loading sets missing selections directly.
  // Each new action clears the previous error unless it supplies another one.
  FieldNoteFormState copyWith({
    String? customerId,
    String? siteId,
    String? status,
    bool? isSaving,
    bool? isSaved,
    String? error,
  }) => FieldNoteFormState(
    customers: customers,
    sites: sites,
    customerId: customerId ?? this.customerId,
    siteId: siteId ?? this.siteId,
    status: status ?? this.status,
    existingNote: existingNote,
    isLoading: isLoading,
    isSaving: isSaving ?? this.isSaving,
    isSaved: isSaved ?? this.isSaved,
    error: error,
  );

  @override
  List<Object?> get props => [
    customers,
    sites,
    customerId,
    siteId,
    status,
    existingNote,
    isLoading,
    isSaving,
    isSaved,
    error,
  ];
}
