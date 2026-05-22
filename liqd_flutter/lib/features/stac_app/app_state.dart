/// Snapshot of a saved app builder session.
class AppStateSnapshot {
  const AppStateSnapshot({
    this.stacJson,
    this.messages = const [],
  });

  final Map<String, dynamic>? stacJson;
  final List<Map<String, String>> messages;

  Map<String, dynamic> toJson() {
    return {
      if (stacJson != null) 'stacJson': stacJson,
      if (messages.isNotEmpty) 'messages': messages,
    };
  }

  static AppStateSnapshot fromSurfaceState(Map<String, dynamic>? state) {
    if (state == null || state.isEmpty) {
      return const AppStateSnapshot();
    }

    final stacJson = state['stacJson'];
    final messages = state['messages'];
    return AppStateSnapshot(
      stacJson: stacJson is Map<String, dynamic> ? stacJson : null,
      messages: _parseMessages(messages),
    );
  }

  static List<Map<String, String>> _parseMessages(Object? raw) {
    if (raw is! List) {
      return const [];
    }

    final messages = <Map<String, String>>[];
    for (final item in raw) {
      if (item is Map && item['role'] is String && item['content'] is String) {
        messages.add({
          'role': item['role'] as String,
          'content': item['content'] as String,
        });
      }
    }
    return messages;
  }
}
