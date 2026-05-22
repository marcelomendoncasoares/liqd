import 'dart:async';

import 'package:genui/genui.dart';
import 'package:liqd_a2ui/liqd_a2ui.dart';
import 'package:liqd_client/liqd_client.dart';

import '../catalog/catalog_builder.dart';
import '../catalog/catalog_manifest_builder.dart';
import '../catalog/stac_template_merger.dart';
import 'gen_ui_stream_logger.dart';
import 'gen_ui_update_outcome.dart';
import 'generation_cancel_token.dart';
import 'serverpod_transport.dart';
import 'surface_context_builder.dart';
import 'ui_interaction.dart';

/// Orchestrates GenUI conversation lifecycle with the basic A2UI catalog.
class GenUiController {
  GenUiController({
    required this.client,
    required this.model,
    Map<String, dynamic>? savedSurfaceState,
  }) {
    _savedSurfaceState = savedSurfaceState;
  }

  final _updateOutcomes = StreamController<GenUiUpdateOutcome>.broadcast();

  final Client client;
  final String model;

  final List<GenUiChatMessage> _messageHistory = [];
  Map<String, dynamic>? _savedSurfaceState;

  List<Catalog> _catalogs = [];
  CatalogManifest? _catalogManifest;
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
  Stream<GenUiUpdateOutcome> get updateOutcomes => _updateOutcomes.stream;

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
    await _trackNewWidgets();
  }

  Future<void> stopGeneration() async {
    if (!_streamInFlight) {
      return;
    }
    _cancelToken?.cancel();
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamInFlight = false;
    _emitStreamOutcome(
      const GenUiUpdateOutcome(
        kind: GenUiUpdateOutcomeKind.cancelled,
        message: 'Generation stopped.',
      ),
    );
  }

  Future<void> retryLastMessage() async {
    if (_conversation == null || _messageHistory.isEmpty) {
      return;
    }
    final last = _messageHistory.last;
    if (last.role != 'user') {
      return;
    }
    await _conversation!.sendRequest(ChatMessage.user(last.content));
    await _trackNewWidgets();
  }

  Future<void> _trackNewWidgets() async {
    await client.widgetCatalog.listMyWidgets();
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
        final surfaceJson = definition.toJson();
        final dataModel = controller.store
            .getDataModel(surfaceId)
            .getValue<Map<String, Object?>>(DataPath.root);
        if (dataModel != null && dataModel.isNotEmpty) {
          surfaceJson['dataModel'] = dataModel.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
        surfaces[surfaceId] = surfaceJson;
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
    await client.widgetCatalog.listMyWidgets();
    _catalogs = CatalogBuilder.buildCatalogs(const []);
    _catalogManifest = CatalogManifestBuilder.buildBasicManifest();
    _rebuildEngine();
  }

  void _rebuildEngine() {
    if (_catalogs.isEmpty || _catalogManifest == null) {
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
    final manifest = _catalogManifest;
    if (transport == null || controller == null || manifest == null) {
      return;
    }

    if (UiInteraction.isErrorFeedback(message) ||
        UiInteraction.isUiInteraction(message)) {
      _emitValidationError(message);
      return;
    }

    if (_streamInFlight) {
      return;
    }

    _cancelToken = GenerationCancelToken();
    _streamInFlight = true;
    final cancelToken = _cancelToken!;

    final parsedMessageTypes = <String>[];
    var surfaceUpdated = false;

    StreamSubscription<A2uiMessage>? incomingSubscription;
    StreamSubscription<SurfaceUpdate>? streamSurfaceSubscription;

    incomingSubscription = transport.incomingMessages.listen((parsed) {
      parsedMessageTypes.add(parsed.runtimeType.toString());
      GenUiStreamLogger.logParsedMessage(parsed);
    });

    streamSurfaceSubscription = controller.surfaceUpdates.listen((update) {
      if (update is ComponentsUpdated || update is SurfaceAdded) {
        surfaceUpdated = true;
      }
    });

    try {
      final rawResponse = await streamGenUiFromServer(
        client: client,
        transport: transport,
        history: List.from(_messageHistory),
        message: message,
        model: model,
        cancelToken: cancelToken,
        catalogManifestJson: manifest.toJsonString(),
        existingSurfacesJson: buildExistingSurfacesJson(controller),
        onSubscription: (subscription) {
          _streamSubscription = subscription;
        },
      );

      GenUiStreamLogger.logStreamComplete(
        rawResponse: rawResponse,
        parsedMessageCount: parsedMessageTypes.length,
        parsedMessageTypes: parsedMessageTypes,
        surfaceUpdated: surfaceUpdated,
      );

      _emitStreamOutcome(
        GenUiUpdateOutcome.evaluate(
          rawResponse: rawResponse,
          parsedMessageCount: parsedMessageTypes.length,
          parsedMessageTypes: parsedMessageTypes,
          surfaceUpdated: surfaceUpdated,
          wasCancelled: cancelToken.isCancelled,
        ),
      );
    } on Object catch (error, stackTrace) {
      GenUiStreamLogger.logError(error, stackTrace);
      rethrow;
    } finally {
      await incomingSubscription.cancel();
      await streamSurfaceSubscription.cancel();
      _cancelToken = null;
      _streamSubscription = null;
      _streamInFlight = false;
    }
  }

  void _emitValidationError(ChatMessage message) {
    final feedback = UiInteraction.parseErrorFeedback(message);
    if (feedback == null) {
      return;
    }

    _emitStreamOutcome(
      GenUiUpdateOutcome.validationFailed(
        message: feedback.message,
        surfaceId: feedback.surfaceId,
        path: feedback.path,
      ),
    );
  }

  void _emitStreamOutcome(GenUiUpdateOutcome outcome) {
    if (!outcome.isWarning) {
      return;
    }
    if (_updateOutcomes.isClosed) {
      return;
    }
    _updateOutcomes.add(outcome);
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
            sendDataModel: true,
          ),
        );
        controller.handleMessage(
          UpdateComponents(
            surfaceId: definition.surfaceId,
            components: definition.components.values.toList(),
          ),
        );
        restoreDataModelForSurface(
          controller,
          definition.surfaceId,
          dataModelFromSurfaceJson(surfaceJson),
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
    unawaited(_updateOutcomes.close());
  }
}
