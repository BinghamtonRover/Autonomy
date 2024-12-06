import "dart:async";

mixin Receiver {
  Completer<void>? _completer;

  bool _hasValue = false;

  set hasValue(bool value) {
    _hasValue = value;
    if (!value) return;
    _completer?.complete();
    _completer = null;
  }

  bool get hasValue => _hasValue;

  Future<void> waitForValue() {
    _completer = Completer<bool>();
    return _completer!.future;
  }
}
