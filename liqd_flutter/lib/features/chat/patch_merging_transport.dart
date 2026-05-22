import 'package:genui/genui.dart';

import 'component_patch_merger.dart';
import 'component_normalizer.dart';

/// Wraps a transport so [UpdateComponents] patches merge into existing surfaces.
final class PatchMergingTransport implements Transport {
  PatchMergingTransport({
    required Transport inner,
    required SurfaceController controller,
  }) : _inner = inner,
       _controller = controller;

  final Transport _inner;
  final SurfaceController _controller;

  @override
  Stream<String> get incomingText => _inner.incomingText;

  @override
  Stream<A2uiMessage> get incomingMessages => _inner.incomingMessages
      .map(_patchMessage)
      .where((message) => message != null)
      .cast<A2uiMessage>();

  @override
  Future<void> sendRequest(ChatMessage message) => _inner.sendRequest(message);

  @override
  void dispose() => _inner.dispose();

  A2uiMessage? _patchMessage(A2uiMessage message) {
    return switch (message) {
      CreateSurface(:final surfaceId)
          when _controller.registry.hasSurface(
            surfaceId,
          ) =>
        null,
      UpdateComponents(:final surfaceId, :final components) => UpdateComponents(
        surfaceId: surfaceId,
        components: ComponentNormalizer.normalize(
          ComponentPatchMerger.merge(
            existing: _controller.registry.getSurface(surfaceId),
            incoming: components,
          ),
        ),
      ),
      _ => message,
    };
  }
}
