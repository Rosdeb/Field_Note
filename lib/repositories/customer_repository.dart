import 'package:uuid/uuid.dart';
import '../core/storage/hive_service.dart';
import '../core/sync/sync_manager.dart';
import '../models/customer.dart';
import '../models/sync_item.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers({String? query});
  Future<Customer?> getCustomerById(String id);
  Future<Customer> saveCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
}

class CustomerRepositoryImpl implements CustomerRepository {
  final HiveService hiveService;
  final SyncManager syncManager;
  final Uuid _uuid = const Uuid();

  CustomerRepositoryImpl({
    required this.hiveService,
    required this.syncManager,
  });

  @override
  Future<List<Customer>> getCustomers({String? query}) async {
    final box = hiveService.customersBox;
    final customers = <Customer>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        final customer = Customer.fromJson(
          (raw as Map).cast<String, dynamic>(),
        );
        if (query == null || query.isEmpty) {
          customers.add(customer);
        } else {
          final q = query.toLowerCase();
          if (customer.name.toLowerCase().contains(q) ||
              customer.contactPerson.toLowerCase().contains(q) ||
              customer.email.toLowerCase().contains(q)) {
            customers.add(customer);
          }
        }
      }
    }

    customers.sort((a, b) => a.name.compareTo(b.name));
    return customers;
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    final raw = hiveService.customersBox.get(id);
    if (raw == null) return null;
    return Customer.fromJson((raw as Map).cast<String, dynamic>());
  }

  @override
  Future<Customer> saveCustomer(Customer customer) async {
    final String customerId = customer.id.isEmpty ? _uuid.v4() : customer.id;
    final int nextVersion = customer.version + 1;
    final updatedCustomer = customer.copyWith(
      id: customerId,
      version: nextVersion,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // 1. Save locally to Hive for instant offline availability
    await hiveService.customersBox.put(customerId, updatedCustomer.toJson());

    // 2. Enqueue sync mutation
    final mutationId = _uuid.v4();
    final mutation = SyncMutation(
      mutationId: mutationId,
      entityType: EntityType.CUSTOMER,
      entityId: customerId,
      operation: SyncOperation.UPSERT,
      expectedVersion: customer.version,
      data: updatedCustomer.toWritePayload(),
      timestamp: DateTime.now(),
    );
    await hiveService.syncMutationsBox.put(mutationId, mutation.toJson());

    // 3. Trigger background sync if connected
    syncManager.scheduleLocalSync();

    return updatedCustomer;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final existing = await getCustomerById(id);
    final expectedVersion = existing?.version ?? 0;

    // 1. Delete locally from Hive
    await hiveService.customersBox.delete(id);

    // 2. Enqueue delete mutation
    final mutationId = _uuid.v4();
    final mutation = SyncMutation(
      mutationId: mutationId,
      entityType: EntityType.CUSTOMER,
      entityId: id,
      operation: SyncOperation.DELETE,
      expectedVersion: expectedVersion,
      data: {'id': id, 'deleted': true},
      timestamp: DateTime.now(),
    );
    await hiveService.syncMutationsBox.put(mutationId, mutation.toJson());

    // 3. Trigger background sync if connected
    syncManager.scheduleLocalSync();
  }
}
