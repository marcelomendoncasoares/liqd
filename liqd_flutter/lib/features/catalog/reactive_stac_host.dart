import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

/// Rebuilds Stac JSON when [StacRegistry] values change (via setValue actions).
class ReactiveStacHost extends StatefulWidget {
  const ReactiveStacHost({
    super.key,
    required this.stacJson,
  });

  final Map<String, dynamic> stacJson;

  /// Notifies the nearest host to rebuild after registry writes.
  static void notifyRegistryChanged(BuildContext context) {
    context
        .findAncestorStateOfType<_ReactiveStacHostState>()
        ?.markRegistryChanged();
  }

  @override
  State<ReactiveStacHost> createState() => _ReactiveStacHostState();
}

class _ReactiveStacHostState extends State<ReactiveStacHost> {
  void markRegistryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stac.fromJson(widget.stacJson, context) ??
        const SizedBox.shrink();
  }
}
