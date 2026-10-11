import 'package:equatable/equatable.dart';
import '../../../models/customer.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final String? query;

  const LoadCustomers({this.query});

  @override
  List<Object?> get props => [query];
}

class SaveCustomerEvent extends CustomerEvent {
  final Customer customer;

  const SaveCustomerEvent({required this.customer});

  @override
  List<Object?> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  final String id;

  const DeleteCustomerEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
