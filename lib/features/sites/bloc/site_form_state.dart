import 'package:equatable/equatable.dart';
import '../../../models/customer.dart';
import '../../../models/site.dart';

class SiteFormState extends Equatable {
  final List<Customer> customers;
  final String? customerId;
  final Site? existingSite;
  final String query;
  final bool isLoading;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const SiteFormState({
    this.customers = const [],
    this.customerId,
    this.existingSite,
    this.query = '',
    this.isLoading = true,
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });

  Customer? get selectedCustomer {
    for (final customer in customers) {
      if (customer.id == customerId) return customer;
    }
    return null;
  }

  List<Customer> get filteredCustomers {
    final search = query.trim().toLowerCase();
    return customers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(search) ||
              customer.contactInformation.toLowerCase().contains(search) ||
              customer.email.toLowerCase().contains(search),
        )
        .toList();
  }

  // Selection events supply a valid non-null ID; new actions clear old errors.
  SiteFormState copyWith({
    String? customerId,
    String? query,
    bool? isSaving,
    bool? isSaved,
    String? error,
  }) => SiteFormState(
    customers: customers,
    customerId: customerId ?? this.customerId,
    existingSite: existingSite,
    query: query ?? this.query,
    isLoading: isLoading,
    isSaving: isSaving ?? this.isSaving,
    isSaved: isSaved ?? this.isSaved,
    error: error,
  );

  @override
  List<Object?> get props => [
    customers,
    customerId,
    existingSite,
    query,
    isLoading,
    isSaving,
    isSaved,
    error,
  ];
}
