import 'package:flutter_driver/driver_extension.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'main.dart' as app;

/// Entry point for Flutter Driver / DTD integration tests.
///
/// Run with: flutter run -t lib/driver_main.dart
void main() {
  enableFlutterDriverExtension();
  app.main();
  _ensureDriverSignedIn();
}

/// Signs in the driver test user so web driver tests skip auth UI.
Future<void> _ensureDriverSignedIn() async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (app.client.auth.isAuthenticated) {
      return;
    }
  }

  try {
    final authSuccess = await app.client.emailIdp.login(
      email: 'liqddriver@test.dev',
      password: 'TestPassword123!',
    );
    await app.client.auth.updateSignedInUser(authSuccess);
  } on Object {
    // Auth UI remains available for manual sign-in during driver runs.
  }
}
