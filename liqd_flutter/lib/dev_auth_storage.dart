import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

/// In-memory auth storage for local driver/dev runs.
///
/// Avoids Linux keyring issues in WSL where [FlutterSecureStorage] can leave
/// the app thinking it is signed in while requests have no valid JWT.
class DevAuthStorage {
  DevAuthStorage._();

  static ClientAuthSuccessStorage create() {
    return KeyValueClientAuthSuccessStorage(
      keyValueStorage: _MemoryKeyValueStorage(),
    );
  }
}

class _MemoryKeyValueStorage implements KeyValueStorage {
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
