import 'package:liqd_client/liqd_client.dart';
import 'package:liqd_flutter/features/catalog/catalog_manifest_builder.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

class _MemoryStorage implements KeyValueStorage {
  final _data = <String, String>{};

  @override
  Future<String?> get(String key) async => _data[key];

  @override
  Future<void> set(String key, String? value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
}

Future<void> main() async {
  final client = Client('http://localhost:8080')
    ..authSessionManager = ClientAuthSessionManager(
      storage: KeyValueClientAuthSuccessStorage(
        keyValueStorage: _MemoryStorage(),
      ),
    );

  final auth = await client.emailIdp.login(
    email: 'liqddriver@test.dev',
    password: 'TestPassword123!',
  );
  await client.auth.updateSignedInUser(auth);

  print(
    'auth header present: ${(await client.auth.authHeaderValue)?.isNotEmpty}',
  );

  final apps = await client.userApp.listApps();
  print('listApps count: ${apps.length}');

  final widgets = await client.widgetCatalog.listMyWidgets();
  print('listMyWidgets count: ${widgets.length}');

  final stream = client.genUiStream.chatStream(
    GenUiChatRequest(
      model: 'deepseek/deepseek-v4-flash:free',
      catalogManifestJson: CatalogManifestBuilder.buildBasicManifest()
          .toJsonString(),
      messages: [
        GenUiChatMessage(role: 'user', content: 'Say hi'),
      ],
    ),
  );
  var chunks = 0;
  await for (final chunk in stream) {
    print('chunk: ${chunk.length > 40 ? chunk.substring(0, 40) : chunk}');
    chunks++;
    if (chunks >= 2) break;
  }
  print('chatStream ok, chunks: $chunks');
}
