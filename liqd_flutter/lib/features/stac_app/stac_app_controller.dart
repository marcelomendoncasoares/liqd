import 'dart:convert';

import 'package:liqd_client/liqd_client.dart';

import 'app_state.dart';
import 'stac_generate_outcome.dart';

/// Orchestrates chat-driven Stac app generation.
class StacAppController {
  StacAppController({
    required this.client,
    required this.model,
    Map<String, dynamic>? savedState,
  }) {
    final snapshot = AppStateSnapshot.fromSurfaceState(savedState);
    _stacJson = snapshot.stacJson;
    for (final message in snapshot.messages) {
      _messageHistory.add(
        StacChatMessage(
          role: message['role']!,
          content: message['content']!,
        ),
      );
    }
  }

  final Client client;
  final String model;

  Map<String, dynamic>? _stacJson;
  final List<StacChatMessage> _messageHistory = [];
  bool _generating = false;

  bool get isGenerating => _generating;
  Map<String, dynamic>? get stacJson => _stacJson;
  List<StacChatMessage> get messageHistory =>
      List.unmodifiable(_messageHistory);

  Future<StacGenerateOutcome> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _generating) {
      return const StacGenerateOutcome(
        kind: StacGenerateOutcomeKind.noStac,
        message: '',
      );
    }

    _messageHistory.add(StacChatMessage(role: 'user', content: trimmed));
    return _generate();
  }

  Future<StacGenerateOutcome> retryLastMessage() async {
    if (_generating || _messageHistory.isEmpty) {
      return const StacGenerateOutcome(
        kind: StacGenerateOutcomeKind.noStac,
        message: '',
      );
    }

    final last = _messageHistory.last;
    if (last.role != 'user') {
      return const StacGenerateOutcome(
        kind: StacGenerateOutcomeKind.noStac,
        message: '',
      );
    }

    return _generate();
  }

  Future<StacGenerateOutcome> _generate() async {
    _generating = true;
    try {
      final response = await client.stacApp.generateApp(
        StacGenerateRequest(
          model: model,
          messages: List.from(_messageHistory),
          existingStacJson: _stacJson == null
              ? null
              : const JsonEncoder.withIndent('  ').convert(_stacJson),
        ),
      );

      final outcome = StacGenerateOutcome.evaluate(
        stacJson: response.stacJson,
        validationErrors: response.validationErrors,
        rawResponse: response.rawResponse,
      );

      if (response.stacJson != null) {
        _stacJson = Map<String, dynamic>.from(response.stacJson!);
      }

      return outcome;
    } on StacGenerateException catch (error) {
      return StacGenerateOutcome(
        kind: StacGenerateOutcomeKind.validationFailed,
        message: error.message,
      );
    } finally {
      _generating = false;
    }
  }

  AppStateSnapshot exportSnapshot() {
    return AppStateSnapshot(
      stacJson: _stacJson == null
          ? null
          : Map<String, dynamic>.from(_stacJson!),
      messages: _messageHistory
          .map((message) => {'role': message.role, 'content': message.content})
          .toList(),
    );
  }
}
