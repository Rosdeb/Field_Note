import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_notes/models/customer.dart';
import 'package:field_notes/models/site.dart';
import 'package:field_notes/models/field_note.dart';
import 'package:field_notes/models/sync_item.dart';
import 'package:field_notes/models/user.dart';
import 'package:field_notes/core/storage/hive_service.dart';
import 'package:field_notes/core/constants/api_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('hive_models_test_');
    hiveService = HiveService();
    await hiveService.init(customPath: tempDir.path);
  });

  tearDownAll(() async {
    tempDir.deleteSync(recursive: true);
  });

  group('Data Models & OpenAPI Schema Compliance', () {
    test('Customer model serializes and deserializes contactInformation correctly', () {
      final json = {
        'id': 'cust-123',
        'name': 'Acme Corp',
        'contactInformation': 'Jane Doe - Lead Architect',
        'phone': '+1 555-0199',
        'email': 'jane@acme.com',
        'address': '123 Market St',
        'version': 3,
      };

      final customer = Customer.fromJson(json);
      expect(customer.id, 'cust-123');
      expect(customer.name, 'Acme Corp');
      expect(customer.contactInformation, 'Jane Doe - Lead Architect');
      expect(customer.contactPerson, 'Jane Doe - Lead Architect');

      final serialized = customer.toJson();
      expect(serialized['contactInformation'], 'Jane Doe - Lead Architect');
      expect(serialized['contactPerson'], 'Jane Doe - Lead Architect');
      expect(serialized['version'], 3);
    });

    test('Site model serializes and deserializes correctly without lat/long', () {
      final json = {
        'id': 'site-456',
        'customerId': 'cust-123',
        'siteName': 'North Power Plant',
        'address': '123 Industrial Area, Sector 4',
        'customerName': 'Acme Corp',
        'version': 2,
      };

      final site = Site.fromJson(json);
      expect(site.id, 'site-456');
      expect(site.customerId, 'cust-123');
      expect(site.name, 'North Power Plant');
      expect(site.siteName, 'North Power Plant');
      expect(site.address, '123 Industrial Area, Sector 4');
      expect(site.customerName, 'Acme Corp');

      final serialized = site.toJson();
      expect(serialized['siteName'], 'North Power Plant');
      expect(serialized['name'], 'North Power Plant');
      expect(serialized['address'], '123 Industrial Area, Sector 4');
      expect(serialized['customerName'], 'Acme Corp');
      expect(serialized.containsKey('latitude'), isFalse);
      expect(serialized.containsKey('longitude'), isFalse);
    });

    test('FieldNote model serializes description, photoId, and occurredAt correctly', () {
      final now = DateTime.now().toUtc();
      final json = {
        'id': 'note-789',
        'siteId': 'site-456',
        'customerId': 'cust-123',
        'title': 'Turbine Inspection',
        'description': 'Found minor grease leak on generator housing.',
        'photoId': 'photo-uuid-001',
        'status': 'IN_PROGRESS',
        'version': 1,
        'createdAt': now.toIso8601String(),
        'occurredAt': now.toIso8601String(),
        'isSynced': true,
      };

      final note = FieldNote.fromJson(json);
      expect(note.id, 'note-789');
      expect(note.description, 'Found minor grease leak on generator housing.');
      expect(note.notes, 'Found minor grease leak on generator housing.');
      expect(note.photoId, 'photo-uuid-001');
      expect(note.photos, contains('photo-uuid-001'));
      expect(note.status, 'IN_PROGRESS');
      expect(note.isSynced, isTrue);

      final serialized = note.toJson();
      expect(serialized['description'], 'Found minor grease leak on generator housing.');
      expect(serialized['notes'], 'Found minor grease leak on generator housing.');
      expect(serialized['photoId'], 'photo-uuid-001');
      expect(serialized['occurredAt'], isNotNull);
    });

    test('Session model parses JWT and Refresh Tokens correctly', () {
      final json = {
        'userId': 'user-1',
        'email': 'inspector@fieldnotes.com',
        'accessToken': 'access-jwt-token',
        'refreshToken': 'refresh-token-xyz',
        'tokenType': 'Bearer',
        'expiresIn': 900,
      };

      final session = Session.fromJson(json);
      expect(session.userId, 'user-1');
      expect(session.effectiveAccessToken, 'access-jwt-token');
      expect(session.refreshToken, 'refresh-token-xyz');
      expect(session.tokenType, 'Bearer');
      expect(session.expiresIn, 900);
    });
  });

  group('HiveService Token Persistence', () {
    test('saveSession, getAuthToken, getRefreshToken and clearSession works', () async {
      await hiveService.saveSession(
        token: 'test-jwt',
        refreshToken: 'test-refresh',
        userJson: {'id': 'user-1', 'email': 'test@example.com'},
      );

      expect(hiveService.getAuthToken(), 'test-jwt');
      expect(hiveService.getRefreshToken(), 'test-refresh');
      expect(hiveService.getSavedUser()?['email'], 'test@example.com');

      await hiveService.saveTokens(
        token: 'new-test-jwt',
        refreshToken: 'new-test-refresh',
      );

      expect(hiveService.getAuthToken(), 'new-test-jwt');
      expect(hiveService.getRefreshToken(), 'new-test-refresh');

      await hiveService.clearSession();
      expect(hiveService.getAuthToken(), isNull);
      expect(hiveService.getRefreshToken(), isNull);
      expect(hiveService.getSavedUser(), isNull);
    });
  });

  group('Sync Mutation Sanitization & toWritePayload', () {
    test('Customer write payload contains only name and contactInformation', () {
      const customer = Customer(
        id: 'cust-1',
        name: 'SparkTech',
        contactPerson: 'Motin Islam',
        phone: '+8801925609656',
        email: 'rosdeb@yopmail.com',
        address: 'Badda, Dhaka',
        version: 1,
      );

      final writePayload = customer.toWritePayload();
      expect(writePayload, {
        'name': 'SparkTech',
        'contactInformation': 'Motin Islam',
      });
      expect(writePayload.containsKey('id'), isFalse);
      expect(writePayload.containsKey('phone'), isFalse);
      expect(writePayload.containsKey('version'), isFalse);
    });

    test('Site write payload contains only siteName, address, and customerId', () {
      const site = Site(
        id: 'site-1',
        customerId: 'cust-1',
        name: 'AQUA Tower',
        address: 'Dhaka, Mohakhali',
        version: 1,
      );

      final writePayload = site.toWritePayload();
      expect(writePayload, {
        'siteName': 'AQUA Tower',
        'address': 'Dhaka, Mohakhali',
        'customerId': 'cust-1',
      });
      expect(writePayload.containsKey('id'), isFalse);
      expect(writePayload.containsKey('version'), isFalse);
    });

    test('FieldNote write payload contains only siteId, title, description, status, occurredAt, photoId', () {
      final now = DateTime.now().toUtc();
      final note = FieldNote(
        id: 'note-1',
        siteId: 'site-1',
        customerId: 'cust-1',
        title: 'Roof Inspection',
        description: 'All clear',
        status: 'COMPLETED',
        createdAt: now,
        occurredAt: now,
        version: 1,
      );

      final writePayload = note.toWritePayload();
      expect(writePayload['siteId'], 'site-1');
      expect(writePayload['title'], 'Roof Inspection');
      expect(writePayload['description'], 'All clear');
      expect(writePayload['status'], 'COMPLETED');
      expect(writePayload.containsKey('id'), isFalse);
      expect(writePayload.containsKey('customerId'), isFalse);
      expect(writePayload.containsKey('version'), isFalse);
    });

    test('SyncMutation.toApiPayload dynamically strips dirty fields from previously queued mutations', () {
      // Simulate raw dirty data previously stored in Hive
      final dirtyCustomerMutation = SyncMutation(
        mutationId: 'm-1',
        entityType: EntityType.CUSTOMER,
        entityId: 'c-1',
        operation: SyncOperation.UPSERT,
        expectedVersion: 0,
        data: {
          'id': 'c-1',
          'name': 'Hey',
          'contactPerson': 'Mr Jong',
          'phone': '++8801925609656',
          'email': 'rosdeb@yopmail.com',
          'address': 'Badda, Dhaka',
          'version': 1,
          'updatedAt': '2026-10-09T12:13:27.724418',
        },
        timestamp: DateTime.now(),
      );

      final cleanPayload = dirtyCustomerMutation.toApiPayload();
      expect(cleanPayload['data'], {
        'name': 'Hey',
        'contactInformation': 'Mr Jong',
      });
      expect((cleanPayload['data'] as Map).containsKey('id'), isFalse);
      expect((cleanPayload['data'] as Map).containsKey('phone'), isFalse);
      expect((cleanPayload['data'] as Map).containsKey('version'), isFalse);
    });

    test('ApiConstants uses BASE_URL from dotenv when loaded', () {
      dotenv.loadFromString(envString: 'BASE_URL=https://custom-api.fieldnotes.com');
      expect(ApiConstants.baseUrl, 'https://custom-api.fieldnotes.com');
    });
  });
}
