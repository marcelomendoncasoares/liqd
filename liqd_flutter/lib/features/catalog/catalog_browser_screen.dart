import 'package:flutter/material.dart';
import 'package:liqd_client/liqd_client.dart';

class CatalogBrowserScreen extends StatefulWidget {
  const CatalogBrowserScreen({super.key, required this.client});

  final Client client;

  @override
  State<CatalogBrowserScreen> createState() => _CatalogBrowserScreenState();
}

class _CatalogBrowserScreenState extends State<CatalogBrowserScreen> {
  List<UserWidget> _widgets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final widgets = await widget.client.widgetCatalog.listMyWidgets();
    if (!mounted) {
      return;
    }
    setState(() {
      _widgets = widgets;
      _loading = false;
    });
  }

  Future<void> _deleteWidget(UserWidget entry) async {
    if (entry.isSeed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seed widgets cannot be deleted')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete widget?'),
        content: Text('Remove "${entry.name}" from your catalog?'),
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
    if (confirmed != true || entry.id == null) {
      return;
    }
    await widget.client.widgetCatalog.deleteWidget(entry.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget catalog'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _widgets.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final widgetDef = _widgets[index];
                return ListTile(
                  title: Text(widgetDef.name),
                  subtitle: Text(widgetDef.description),
                  trailing: widgetDef.isSeed
                      ? const Chip(label: Text('Seed'))
                      : IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteWidget(widgetDef),
                        ),
                );
              },
            ),
    );
  }
}
