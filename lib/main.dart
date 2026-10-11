import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If .env is missing or fails to load, ApiConstants will safely fallback to defaultBaseUrl
  }
  await ServiceLocator().init();
  runApp(const FieldNotesApp());
}
