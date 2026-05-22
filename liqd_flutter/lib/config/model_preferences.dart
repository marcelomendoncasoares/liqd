import '../../config/app_config.dart';

/// In-memory model selection (SharedPreferences is unavailable on WASM web).
abstract final class ModelPreferences {
  static String _selectedModel = defaultModel;

  static Future<String> getSelectedModel() async => _selectedModel;

  static Future<void> setSelectedModel(String model) async {
    _selectedModel = model;
  }
}
