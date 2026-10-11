import 'dart:io';

import 'package:field_notes/core/di/service_locator.dart';
import 'package:field_notes/features/field_notes/bloc/field_note_form_bloc.dart';
import 'package:field_notes/features/field_notes/screens/field_note_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  final services = ServiceLocator();
  late Directory directory;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    directory = await Directory.systemTemp.createTemp('note_form_');
    await services.init(customStoragePath: directory.path);
  });
  setUp(() async {
    await services.hiveService.clearAllData();
    await services.hiveService.customersBox.put('customer', {
      'id': 'customer',
      'name': 'Customer',
    });
    await services.hiveService.sitesBox.put('site', {
      'id': 'site',
      'customerId': 'customer',
      'name': 'Site',
    });
  });
  tearDownAll(() async {
    services.syncManager.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> editNote(
    WidgetTester tester,
    Map<String, dynamic> overrides,
  ) async {
    await tester.runAsync(() async {
      await services.hiveService.notesBox.put('note', {
        'id': 'note',
        'title': 'Inspection',
        'siteId': 'site',
        'customerId': '',
        'status': 'OPEN',
        ...overrides,
      });
    });
    await tester.pumpWidget(
      const MaterialApp(home: FieldNoteFormScreen(noteId: 'note')),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Customer omitted by server is derived from the site', (
    tester,
  ) async {
    await editNote(tester, {});
    final dropdowns = tester
        .widgetList<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .toList();
    expect(dropdowns[0].initialValue, 'customer');
    expect(dropdowns[1].initialValue, 'site');
  });

  testWidgets('Missing customer and site show prompts without crashing', (
    tester,
  ) async {
    await editNote(tester, {'customerId': 'missing', 'siteId': 'missing'});
    expect(find.text('Select a customer'), findsOneWidget);
    expect(find.text('Select a site'), findsOneWidget);
    await tester.ensureVisible(find.text('Update Note'));
    await tester.tap(find.text('Update Note'));
    await tester.pump();
    expect(find.text('Please select a site before saving.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Duplicate and empty dropdown IDs do not crash the form', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await services.hiveService.customersBox.put('duplicate', {
        'id': 'customer',
        'name': 'Duplicate customer',
      });
      await services.hiveService.customersBox.put('empty', {
        'id': '',
        'name': 'Empty',
      });
      await services.hiveService.sitesBox.put('duplicate', {
        'id': 'site',
        'customerId': 'customer',
        'name': 'Duplicate site',
      });
    });
    await editNote(tester, {});
  });

  testWidgets('Unknown server status remains selectable without crashing', (
    tester,
  ) async {
    await editNote(tester, {'status': 'ARCHIVED'});
    expect(find.text('ARCHIVED'), findsOneWidget);
  });

  test(
    'Form BLoC validates before saving and preserves edited note metadata',
    () async {
      const occurredAt = '2026-10-10T02:18:16.221083Z';
      await services.hiveService.notesBox.put('note', {
        'id': 'note',
        'title': 'Original',
        'siteId': 'site',
        'customerId': 'customer',
        'occurredAt': occurredAt,
        'photoId': 'photo',
        'version': 3,
      });
      final bloc = FieldNoteFormBloc(
        customerRepository: services.customerRepository,
        siteRepository: services.siteRepository,
        fieldNoteRepository: services.fieldNoteRepository,
      );
      addTearDown(bloc.close);
      final loaded = bloc.stream.firstWhere((state) => !state.isLoading);
      bloc.add(const LoadFieldNoteForm(noteId: 'note'));
      await loaded;
      final invalid = bloc.stream.firstWhere((state) => state.error != null);
      bloc.add(const SubmitFieldNoteForm(title: ' ', notes: ''));
      expect((await invalid).error, 'Note title is required');
      expect(services.hiveService.syncMutationsBox.isEmpty, isTrue);

      final saved = bloc.stream.firstWhere((state) => state.isSaved);
      bloc.add(
        const SubmitFieldNoteForm(
          title: ' Updated ',
          notes: ' New observations ',
        ),
      );
      await saved;
      final note = await services.fieldNoteRepository.getFieldNoteById('note');
      expect(note!.title, 'Updated');
      expect(note.description, 'New observations');
      expect(note.occurredAt.toUtc().toIso8601String(), occurredAt);
      expect(note.photoId, 'photo');
      expect(services.hiveService.syncMutationsBox.length, 1);
    },
  );

  testWidgets('Selection events keep user text intact', (tester) async {
    await editNote(tester, {});
    await tester.enterText(find.byType(TextField).first, '');
    final context = tester.element(find.byType(TextField).first);
    final bloc = context.read<FieldNoteFormBloc>();
    bloc.add(const SelectNoteStatus('COMPLETED'));
    await tester.pumpAndSettle();
    expect(bloc.state.status, 'COMPLETED');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '',
    );
  });
}
