import 'dart:async';

import 'package:genui/genui.dart';
import 'package:liqd_client/liqd_client.dart';

import '../catalog/catalog_builder.dart';
import '../catalog/stac_template_merger.dart';
import 'generation_cancel_token.dart';
import 'local_action_handler.dart';
import 'serverpod_transport.dart';

/// Orchestrates GenUI conversation lifecycle with a dynamic user catalog.
class GenUiController {
  GenUiController({
    required this.client,
    required this.model,
    Map<String, dynamic>? savedSurfaceState,
  }) {
    _savedSurfaceState = savedSurfaceState;
  }

  final Client client;
  final String model;

  final List<GenUiChatMessage> _messageHistory = [];
  Map<String, dynamic>? _savedSurfaceState;
  int _userWidgetCount = 0;

  List<Catalog> _catalogs = [];
  SurfaceController? _surfaceController;
  A2uiTransportAdapter? _transport;
  Conversation? _conversation;
  bool _streamInFlight = false;
  GenerationCancelToken? _cancelToken;
  StreamSubscription<String>? _streamSubscription;

  bool get isGenerating => _streamInFlight;

  Catalog? get catalog => _catalogs.isNotEmpty ? _catalogs.last : null;
  SurfaceController? get surfaceController => _surfaceController;
  Conversation? get conversation => _conversation;
  List<GenUiChatMessage> get messageHistory =>
      List.unmodifiable(_messageHistory);

  Future<void> initialize() async {
    await _loadCatalog();
    if (_savedSurfaceState != null) {
      _restoreSurfaces(_savedSurfaceState!);
      _savedSurfaceState = null;
    }
  }

  Future<void> reloadCatalog() async {
    await _loadCatalog();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _conversation == null) {
      return;
    }

    _messageHistory.add(GenUiChatMessage(role: 'user', content: trimmed));
    await _conversation!.sendRequest(ChatMessage.user(trimmed));
    await _reloadCatalogIfNewWidgets();
  }

  /// Cancels the active server generation stream, if any.
  Future<void> stopGeneration() async {
    _cancelToken?.cancel();
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamInFlight = false;
  }

  /// Re-sends the last user message without duplicating history.
  Future<void> retryLastMessage() async {
    if (_conversation == null || _messageHistory.isEmpty) {
      return;
    }
    final last = _messageHistory.last;
    if (last.role != 'user') {
      return;
    }
    await _conversation!.sendRequest(ChatMessage.user(last.content));
    await _reloadCatalogIfNewWidgets();
  }

  /// Refreshes the catalog only when the server saved new widgets.
  Future<void> _reloadCatalogIfNewWidgets() async {
    final widgets = await client.widgetCatalog.listMyWidgets();
    if (widgets.length <= _userWidgetCount) {
      return;
    }

    _userWidgetCount = widgets.length;
    final snapshot = exportSnapshot();
    _catalogs = CatalogBuilder.buildCatalogs(widgets);
    _rebuildEngine();
    _restoreSurfaces({'surfaces': snapshot.surfaces});
  }

  SurfaceControllerSnapshot exportSnapshot() {
    final controller = _surfaceController;
    if (controller == null) {
      return SurfaceControllerSnapshot(surfaces: {});
    }

    final surfaces = <String, dynamic>{};
    for (final surfaceId in controller.activeSurfaceIds) {
      final definition = controller.registry.getSurface(surfaceId);
      if (definition != null) {
        surfaces[surfaceId] = definition.toJson();
      }
    }

    return SurfaceControllerSnapshot(
      surfaces: surfaces,
      messages: _messageHistory
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
    );
  }

  Future<void> _loadCatalog() async {
    final widgets = await client.widgetCatalog.listMyWidgets();
    _userWidgetCount = widgets.length;
    _catalogs = CatalogBuilder.buildCatalogs(widgets);
    _rebuildEngine();
  }

  void _rebuildEngine() {
    if (_catalogs.isEmpty) {
      return;
    }

    _conversation?.dispose();
    _transport?.dispose();
    _surfaceController?.dispose();

    _surfaceController = SurfaceController(catalogs: _catalogs);
    _transport = A2uiTransportAdapter(onSend: _handleSend);
    _conversation = Conversation(
      controller: _surfaceController!,
      transport: _transport!,
    );
  }

  Future<void> _handleSend(ChatMessage message) async {
    final transport = _transport;
    final controller = _surfaceController;
    if (transport == null || controller == null) {
      return;
    }

    // GenUI forwards validation/runtime errors to onSubmit, which would
    // otherwise trigger a new OpenRouter call per error (rate-limit storm).
    if (LocalActionHandler.isErrorFeedback(message)) {
      return;
    }

    if (LocalActionHandler.tryHandle(
      controller: controller,
      message: message,
    )) {
      return;
    }

    if (_streamInFlight) {
      return;
    }

    _cancelToken = GenerationCancelToken();
    _streamInFlight = true;
    try {
      await streamGenUiFromServer(
        client: client,
        transport: transport,
        history: List.from(_messageHistory),
        message: message,
        model: model,
        cancelToken: _cancelToken!,
        onSubscription: (subscription) {
          _streamSubscription = subscription;
        },
      );
    } finally {
      _cancelToken = null;
      _streamSubscription = null;
      _streamInFlight = false;
    }
  }

  void _restoreSurfaces(Map<String, dynamic> state) {
    final surfaces = state['surfaces'];
    if (surfaces is! Map) {
      return;
    }

    final controller = _surfaceController;
    if (controller == null) {
      return;
    }

    for (final entry in surfaces.entries) {
      final surfaceJson = entry.value;
      if (surfaceJson is! Map<String, dynamic>) {
        continue;
      }
      try {
        final definition = SurfaceDefinition.fromJson(
          surfaceJson.cast<String, Object?>(),
        );
        controller.handleMessage(
          CreateSurface(
            surfaceId: definition.surfaceId,
            catalogId: definition.catalogId,
          ),
        );
        controller.handleMessage(
          UpdateComponents(
            surfaceId: definition.surfaceId,
            components: definition.components.values.toList(),
          ),
        );
      } on Object {
        // Skip invalid saved surfaces.
      }
    }

    final messages = state['messages'];
    if (messages is List) {
      for (final item in messages) {
        if (item is Map &&
            item['role'] is String &&
            item['content'] is String) {
          _messageHistory.add(
            GenUiChatMessage(
              role: item['role'] as String,
              content: item['content'] as String,
            ),
          );
        }
      }
    }
  }

  void dispose() {
    _cancelToken?.cancel();
    _streamSubscription?.cancel();
    _conversation?.dispose();
    _transport?.dispose();
    _surfaceController?.dispose();
  }
}
