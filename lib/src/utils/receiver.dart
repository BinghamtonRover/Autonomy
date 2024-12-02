import "dart:async";

mixin Receiver {
  final Completer<bool> _value = Completer();

  set hasValue(bool value) {
    if (!_value.isCompleted) {
      _value.complete(value);
    }
  }

  bool get hasValue => _value.isCompleted;
  
  Future<bool> waitForValue() => _value.future;
}
