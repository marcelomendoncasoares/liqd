import 'package:liqd_flutter/features/stac_app/app_state.dart';
import 'package:test/test.dart';

void main() {
  group('AppStateSnapshot', () {
    test('round-trips stacJson and messages', () {
      const snapshot = AppStateSnapshot(
        stacJson: {'type': 'text', 'data': 'Hi'},
        messages: [
          {'role': 'user', 'content': 'Build a counter'},
        ],
      );

      final json = snapshot.toJson();
      final restored = AppStateSnapshot.fromSurfaceState(json);

      expect(restored.stacJson, snapshot.stacJson);
      expect(restored.messages, snapshot.messages);
    });

    test('returns empty snapshot for legacy GenUI surface state', () {
      final restored = AppStateSnapshot.fromSurfaceState({
        'surfaces': {'main': {}},
      });

      expect(restored.stacJson, isNull);
      expect(restored.messages, isEmpty);
    });
  });
}
