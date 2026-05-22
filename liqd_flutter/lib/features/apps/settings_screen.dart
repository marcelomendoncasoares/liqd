import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../config/model_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedModel = defaultModel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final model = await ModelPreferences.getSelectedModel();
    setState(() {
      _selectedModel = model;
      _loading = false;
    });
  }

  Future<void> _saveModel(String? model) async {
    if (model == null) {
      return;
    }
    await ModelPreferences.setSelectedModel(model);
    setState(() {
      _selectedModel = model;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'OpenRouter model',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedModel),
                  initialValue: availableModels.contains(_selectedModel)
                      ? _selectedModel
                      : availableModels.first,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Model',
                  ),
                  items: [
                    for (final model in availableModels)
                      DropdownMenuItem(value: model, child: Text(model)),
                  ],
                  onChanged: _saveModel,
                ),
                const SizedBox(height: 24),
                Text(
                  'The API key is configured on the server. Change models here '
                  'to experiment with different LLMs via OpenRouter.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
