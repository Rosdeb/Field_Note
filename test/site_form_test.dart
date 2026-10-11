import 'dart:io';

import 'package:field_notes/core/di/service_locator.dart';
import 'package:field_notes/features/sites/bloc/site_form_bloc.dart';
import 'package:field_notes/features/sites/screens/site_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  final services = ServiceLocator();
  late Directory directory;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    directory = await Directory.systemTemp.createTemp('site_form_');
    await services.init(customStoragePath: directory.path);
  });
  setUp(() async {
    await services.hiveService.clearAllData();
    await services.hiveService.customersBox.put('alpha', {
      'id': 'alpha',
      'name': 'Alpha',
      'contactInformation': 'Jane',
    });
    await services.hiveService.customersBox.put('beta', {
      'id': 'beta',
      'name': 'Beta',
      'contactInformation': 'John',
    });
  });
  tearDownAll(() async {
    services.syncManager.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> openForm(WidgetTester tester, {String? siteId}) async {
    await tester.pumpWidget(MaterialApp(home: SiteFormScreen(siteId: siteId)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Search filters by contact and selects the customer', (
    tester,
  ) async {
    await openForm(tester);
    expect(find.text('Select a customer'), findsOneWidget);
    await tester.tap(find.text('Select a customer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'John');
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No customers match your search.'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Beta');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Beta'));
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    final bloc = tester
        .element(find.byType(TextField).first)
        .read<SiteFormBloc>();
    expect(bloc.state.customerId, 'beta');
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(bloc.state.customerId, 'beta');
  });

  testWidgets(
    'Missing stored customer requires a replacement without crashing',
    (tester) async {
      await tester.runAsync(() async {
        await services.hiveService.sitesBox.put('site', {
          'id': 'site',
          'name': 'Inspection site',
          'customerId': 'missing',
        });
        await services.hiveService.customersBox.put('duplicate', {
          'id': 'alpha',
          'name': 'Alpha',
        });
        await services.hiveService.customersBox.put('empty', {
          'id': '',
          'name': 'Empty',
        });
      });
      await openForm(tester, siteId: 'site');
      expect(
        find.text(
          'The previous customer is unavailable. Select another customer.',
        ),
        findsOneWidget,
      );
      final bloc = tester
          .element(find.byType(TextField).first)
          .read<SiteFormBloc>();
      expect(bloc.state.customers, hasLength(2));
      expect(bloc.state.customerId, isNull);
    },
  );

  testWidgets('Empty customer list offers creation', (tester) async {
    await tester.runAsync(() => services.hiveService.customersBox.clear());
    await openForm(tester);
    expect(find.text('Add customer'), findsOneWidget);
    expect(find.text('Add a customer before creating a site.'), findsOneWidget);
  });

  test('BLoC preserves edited site metadata', () async {
    await services.hiveService.sitesBox.put('site', {
      'id': 'site',
      'name': 'Original',
      'customerId': 'alpha',
      'version': 4,
      'createdAt': '2026-10-10T00:00:00Z',
    });
    final bloc = SiteFormBloc(
      customerRepository: services.customerRepository,
      siteRepository: services.siteRepository,
    );
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere((state) => !state.isLoading);
    bloc.add(const LoadSiteForm(siteId: 'site'));
    await loaded;
    final selected = bloc.stream.firstWhere(
      (state) => state.customerId == 'beta',
    );
    bloc.add(const SelectSiteCustomer('beta'));
    await selected;
    final saved = bloc.stream.firstWhere((state) => state.isSaved);
    bloc.add(const SubmitSiteForm(name: ' Updated ', address: ' Dhaka '));
    await saved;
    final site = await services.siteRepository.getSiteById('site');
    expect(site!.customerId, 'beta');
    expect(site.name, 'Updated');
    expect(site.address, 'Dhaka');
    expect(site.createdAt, '2026-10-10T00:00:00Z');
    expect(site.version, 5);
  });

  test('New form does not save with an unselected customer', () async {
    final bloc = SiteFormBloc(
      customerRepository: services.customerRepository,
      siteRepository: services.siteRepository,
    );
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere((state) => !state.isLoading);
    bloc.add(const LoadSiteForm());
    await loaded;
    final invalid = bloc.stream.firstWhere((state) => state.error != null);
    bloc.add(const SubmitSiteForm(name: 'Site', address: 'Dhaka'));
    expect((await invalid).error, 'Please select a customer.');
    expect(services.hiveService.sitesBox.isEmpty, isTrue);
  });
}
