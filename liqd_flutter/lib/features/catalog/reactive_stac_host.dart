import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

import 'stac_preview_normalizer.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeStacForPreview(widget.stacJson);
    return Stac.fromJson(normalized, context) ?? const SizedBox.shrink();
  }
}
