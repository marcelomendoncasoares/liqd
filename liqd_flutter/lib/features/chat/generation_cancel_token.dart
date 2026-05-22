/// Signals that an in-flight GenUI generation should stop.
class GenerationCancelToken {
  bool _isCancelled = false;
  final _listeners = <void Function()>{};

  bool get isCancelled => _isCancelled;

  void onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
    _listeners.clear();
  }
}
