import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_notes/app.dart';
import 'package:field_notes/core/di/service_locator.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    await ServiceLocator().init(customStoragePath: tempDir.path);
  });

  testWidgets('Field Notes app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FieldNotesApp());
    await tester.pumpAndSettle();
    expect(find.text('Field Notes'), findsWidgets);
  });
}
