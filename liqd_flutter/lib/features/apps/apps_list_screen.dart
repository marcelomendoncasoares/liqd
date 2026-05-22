import 'package:flutter/material.dart';
import 'package:liqd_client/liqd_client.dart';
import 'package:serverpod_client/serverpod_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../config/model_preferences.dart';
import '../catalog/catalog_browser_screen.dart';
import 'app_builder_screen.dart';

class AppsListScreen extends StatefulWidget {
  const AppsListScreen({
    super.key,
    required this.client,
    required this.onSignOut,
  });

  final Client client;
  final Future<void> Function() onSignOut;

  @override
  State<AppsListScreen> createState() => _AppsListScreenState();
}

class _AppsListScreenState extends State<AppsListScreen> {
  List<UserApp> _apps = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apps = await widget.client.userApp.listApps();
      if (!mounted) {
        return;
      }
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } on ServerpodClientUnauthorized {
      await widget.client.auth.signOutDevice();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openNewApp() async {
    try {
      final model = await ModelPreferences.getSelectedModel();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AppBuilderScreen(
            client: widget.client,
            model: model,
          ),
        ),
      );
      await _loadApps();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open builder: $error')),
      );
    }
  }

  Future<void> _openApp(UserApp app) async {
    try {
      final model = await ModelPreferences.getSelectedModel();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AppBuilderScreen(
            client: widget.client,
            model: model,
            existingApp: app,
          ),
        ),
      );
      await _loadApps();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open app: $error')),
      );
    }
  }

  Future<void> _deleteApp(UserApp app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete app?'),
        content: Text('Delete "${app.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.client.userApp.deleteApp(app.id!);
    await _loadApps();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).pushNamed('/settings');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liqd'),
        actions: [
          IconButton(
            icon: const Icon(Icons.widgets_outlined),
            tooltip: 'Widget catalog',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CatalogBrowserScreen(client: widget.client),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onSignOut,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('new_app_fab'),
        onPressed: _openNewApp,
        icon: const Icon(Icons.add),
        label: const Text('New app'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadApps, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_apps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Build apps with AI',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Describe what you want and Liqd will compose interactive UI '
                'from your personal widget catalog.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApps,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _apps.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final app = _apps[index];
          return Card(
            child: ListTile(
              title: Text(app.title),
              subtitle: Text(
                'Updated ${_formatDate(app.updatedAt)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteApp(app),
              ),
              onTap: () => _openApp(app),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
