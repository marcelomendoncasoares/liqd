import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:liqd_client/liqd_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'main.dart' as app;

/// Entry point for Flutter Driver / DTD integration tests.
///
/// Run with: flutter run -t lib/driver_main.dart
Future<void> main() async {
  // Real keyboard input requires disabling text-entry emulation.
  // Flutter Driver can re-enable emulation in tests via setTextEntryEmulation.
  enableFlutterDriverExtension(enableTextEntryEmulation: false);
  await app.setupLiqd(useDevAuthStorage: true);
  await ensureDriverSignedIn(app.client);
  runApp(const app.LiqdApp());
}

/// Signs in the driver test user before the UI mounts.
Future<void> ensureDriverSignedIn(Client client) async {
  if (client.auth.isAuthenticated) {
    await client.auth.signOutDevice();
  }

  const email = 'liqddriver@test.dev';
  const password = 'TestPassword123!';

  try {
    final authSuccess = await client.emailIdp.login(
      email: email,
      password: password,
    );
    await client.auth.updateSignedInUser(authSuccess);
  } on Object catch (error) {
    debugPrint('Driver auto sign-in failed: $error');
  }
}
