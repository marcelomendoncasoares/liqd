import 'package:liqd_client/liqd_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:stac/stac.dart';

import 'features/catalog/liqd_stac_setup.dart';
import 'dev_auth_storage.dart';
import 'features/apps/apps_list_screen.dart';
import 'features/apps/settings_screen.dart';
import 'screens/sign_in_screen.dart';

late final Client client;

/// Shared bootstrap for [main] and [driver_main].
Future<void> setupLiqd({bool useDevAuthStorage = false}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Stac.initialize();
  LiqdStacSetup.register();

  final serverUrl = await getServerUrl();

  client =
      Client(
          serverUrl,
          connectionTimeout: const Duration(seconds: 60),
          streamingConnectionTimeout: const Duration(seconds: 60),
        )
        ..connectivityMonitor = FlutterConnectivityMonitor()
        ..authSessionManager = FlutterAuthSessionManager(
          storage: useDevAuthStorage ? DevAuthStorage.create() : null,
        );

  await client.auth.initialize();
}

void main() async {
  await setupLiqd();
  runApp(const LiqdApp());
}

class LiqdApp extends StatelessWidget {
  const LiqdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liqd',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
      home: SignInScreen(
        client: client,
        child: AppsListScreen(
          client: client,
          onSignOut: () async {
            await client.auth.signOutDevice();
          },
        ),
      ),
    );
  }
}
