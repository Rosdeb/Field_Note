import 'package:flutter_bloc/flutter_bloc.dart';
import 'customer_event.dart';
import 'customer_state.dart';
import '../../../repositories/customer_repository.dart';

export 'customer_event.dart';
export 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository customerRepository;

  CustomerBloc({required this.customerRepository}) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SaveCustomerEvent>(_onSaveCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final customers = await customerRepository.getCustomers(query: event.query);
      emit(CustomerLoaded(customers: customers, searchQuery: event.query));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }

  Future<void> _onSaveCustomer(
    SaveCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await customerRepository.saveCustomer(event.customer);
      emit(const CustomerActionSuccess(message: 'Customer saved successfully'));
      final customers = await customerRepository.getCustomers();
      emit(CustomerLoaded(customers: customers));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await customerRepository.deleteCustomer(event.id);
      emit(const CustomerActionSuccess(message: 'Customer deleted successfully'));
      final customers = await customerRepository.getCustomers();
      emit(CustomerLoaded(customers: customers));
    } catch (e) {
      emit(CustomerError(message: e.toString()));
    }
  }
}
