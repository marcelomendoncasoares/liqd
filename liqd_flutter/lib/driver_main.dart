import 'package:flutter_driver/driver_extension.dart';

import 'main.dart' as app;

/// Entry point for Flutter Driver / DTD integration tests.
///
/// Run with: flutter run -t lib/driver_main.dart
void main() {
  enableFlutterDriverExtension();
  app.main();
}
