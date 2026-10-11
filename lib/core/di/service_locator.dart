import '../network/api_client.dart';
import '../network/network_info.dart';
import '../storage/hive_service.dart';
import '../sync/sync_manager.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/field_note_repository.dart';
import '../../repositories/photo_repository.dart';
import '../../repositories/site_repository.dart';
import '../../repositories/sync_repository.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final HiveService hiveService;
  late final NetworkInfo networkInfo;
  late final ApiClient apiClient;
  late final SyncManager syncManager;

  late final AuthRepository authRepository;
  late final CustomerRepository customerRepository;
  late final SiteRepository siteRepository;
  late final FieldNoteRepository fieldNoteRepository;
  late final PhotoRepository photoRepository;
  late final SyncRepository syncRepository;

  Future<void> init({String? customStoragePath}) async {
    hiveService = HiveService();
    await hiveService.init(customPath: customStoragePath);

    networkInfo = NetworkInfoImpl();
    apiClient = ApiClient(
      hiveService: hiveService,
      onUnauthorized: () {
        hiveService.clearSession();
      },
    );
    syncManager = SyncManager(
      apiClient: apiClient,
      networkInfo: networkInfo,
      hiveService: hiveService,
    );

    authRepository = AuthRepositoryImpl(
      apiClient: apiClient,
      hiveService: hiveService,
      syncManager: syncManager,
    );

    customerRepository = CustomerRepositoryImpl(
      hiveService: hiveService,
      syncManager: syncManager,
    );

    siteRepository = SiteRepositoryImpl(
      hiveService: hiveService,
      syncManager: syncManager,
    );

    fieldNoteRepository = FieldNoteRepositoryImpl(
      hiveService: hiveService,
      syncManager: syncManager,
    );

    photoRepository = PhotoRepositoryImpl(
      apiClient: apiClient,
    );

    syncRepository = SyncRepositoryImpl(
      hiveService: hiveService,
      syncManager: syncManager,
    );
  }
}
