import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:field_notes/core/network/api_client.dart';
import 'package:field_notes/core/network/interceptors/logging_interceptor.dart';
import 'package:field_notes/core/network/network_info.dart';
import 'package:field_notes/core/storage/hive_service.dart';
import 'package:field_notes/core/sync/sync_manager.dart';
import 'package:field_notes/models/sync_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FakeNetwork implements NetworkInfo {
  bool connected = true;
  int checks = 0;
  final changes = StreamController<bool>.broadcast();
  @override
  Future<bool> get isConnected async {
    checks++;
    return connected;
  }

  @override
  Stream<bool> get onConnectivityChanged => changes.stream;
}

class SyncAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool unavailable = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (unavailable) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final data = options.method == 'POST'
        ? {
            'results': [
              for (final mutation in options.data['mutations'] as List)
                {...mutation as Map, 'version': 1, 'revision': 1},
            ],
          }
        : {'changes': [], 'nextCursor': 0, 'hasMore': false};
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory directory;
  late HiveService storage;
  late FakeNetwork network;
  late SyncAdapter adapter;
  late SyncManager manager;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    directory = await Directory.systemTemp.createTemp('local_sync_');
    storage = HiveService();
    await storage.init(customPath: directory.path);
    await storage.saveSession(token: 'test', userJson: {'id': 'user'});
    network = FakeNetwork();
    adapter = SyncAdapter();
    final api = ApiClient(baseUrl: 'http://localhost', hiveService: storage);
    api.dio.interceptors.removeWhere((item) => item is LoggingInterceptor);
    api.dio.httpClientAdapter = adapter;
    manager = SyncManager(
      apiClient: api,
      networkInfo: network,
      hiveService: storage,
    );
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    manager.dispose();
    await network.changes.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> queue(int index) async {
    final mutation = SyncMutation(
      mutationId: 'change-$index',
      entityType: EntityType.CUSTOMER,
      entityId: 'customer-$index',
      operation: SyncOperation.UPSERT,
      expectedVersion: 0,
      data: {'name': 'Customer $index'},
      timestamp: DateTime.now(),
    );
    await storage.syncMutationsBox.put(mutation.mutationId, mutation.toJson());
  }

  test(
    'Empty queue and reconnect make no requests or connectivity checks',
    () async {
      manager.scheduleLocalSync();
      network.changes.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      expect(adapter.requests, isEmpty);
      expect(network.checks, 0);
    },
  );

  test('Nearby saves share one push and do not download', () async {
    await queue(1);
    manager.scheduleLocalSync();
    await queue(2);
    manager.scheduleLocalSync();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.data['mutations'], hasLength(2));
    expect(storage.syncMutationsBox.isEmpty, isTrue);
  });

  test('Automatic upload drains more than 100 queued changes', () async {
    for (int i = 0; i < 101; i++) {
      await queue(i);
    }
    expect(await manager.syncAll(pullRemoteChanges: false), 101);
    expect(adapter.requests, hasLength(2));
    expect(storage.syncMutationsBox.isEmpty, isTrue);
  });

  test(
    'Failed upload makes one request and keeps changes for reconnect',
    () async {
      await queue(1);
      adapter.unavailable = true;
      await expectLater(
        manager.syncAll(pullRemoteChanges: false),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(1));
      expect(storage.syncMutationsBox.length, 1);
      adapter.unavailable = false;
      network.changes.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(adapter.requests, hasLength(2));
      expect(storage.syncMutationsBox.isEmpty, isTrue);
    },
  );

  test('Manual sync still downloads when there are no local changes', () async {
    await manager.syncAll(throwOnError: true);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.method, 'GET');
  });
}
