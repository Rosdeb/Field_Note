import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/customer_bloc.dart';
import '../../sync/bloc/sync_bloc.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/customer.dart';
import '../../../routes/app_router.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(const LoadCustomers());
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    context.read<CustomerBloc>().add(LoadCustomers(query: query));
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}? This will queue for sync.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<CustomerBloc>().add(DeleteCustomerEvent(id: customer.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppSearchBar(
              hintText: 'Search customers...',
              onChanged: _onSearchChanged,
              onClear: () => _onSearchChanged(''),
            ),
          ),
          Expanded(
            child: BlocConsumer<CustomerBloc, CustomerState>(
              listener: (context, state) {
                if (state is CustomerActionSuccess) {
                  FloatingSuccessBar.show(context, message: state.message);
                } else if (state is CustomerError) {
                  FloatingErrorBar.show(context, message: state.message);
                }
              },
              builder: (context, state) {
                if (state is CustomerLoading) {
                  return const LoadingView(message: 'Loading customers...');
                }

                if (state is CustomerLoaded) {
                  final customers = state.customers;
                  if (customers.isEmpty) {
                    return EmptyView(
                      icon: Icons.business_outlined,
                      title: _searchQuery.isEmpty ? 'No Customers Found' : 'No Matching Customers',
                      subtitle: _searchQuery.isEmpty
                          ? 'Add your first customer to start tracking site notes.'
                          : 'Try adjusting your search terms.',
                      actionText: 'Add Customer',
                      onActionPressed: () => context.push(AppRouter.customerForm),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<SyncBloc>().add(TriggerSyncRequested());
                      context.read<CustomerBloc>().add(LoadCustomers(query: _searchQuery));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return AppCard(
                          onTap: () => context.push(AppRouter.customerForm, extra: customer.id),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.teal.shade50,
                                child: Text(
                                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (customer.contactPerson.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        customer.contactPerson,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                    ],
                                    if (customer.email.isNotEmpty || customer.phone.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        customer.email.isNotEmpty ? customer.email : customer.phone,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Image.asset("assets/icons/trash (1).png", height: 20, color: Colors.redAccent),
                                onPressed: () => _deleteCustomer(customer),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRouter.customerForm),
        tooltip: 'Add Customer',
        child: const Icon(Icons.add),
      ),
    );
  }
}
