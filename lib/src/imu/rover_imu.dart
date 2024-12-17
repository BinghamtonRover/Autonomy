import "package:autonomy/interfaces.dart";

class RoverImu extends ImuInterface {
  final _xCorrector = ErrorCorrector.disabled();
  final _yCorrector = ErrorCorrector.disabled();
  final _zCorrector = ErrorCorrector.disabled();
  RoverImu({required super.collection});

  @override
  Future<bool> init() async {
    collection.server.messages.onMessage(
      name: RoverPosition().messageName,
      constructor: RoverPosition.fromBuffer,
      callback: _internalUpdate,
    );
    return super.init();
  }

  @override
  Future<void> dispose() async {
    _zCorrector.clear();
  }

  @override
  void update(Orientation newValue) {
    // Do nothing, since this should only be internally updated
  }

  @override
  void forceUpdate(Orientation newValue) =>
      _internalUpdate(RoverPosition(orientation: newValue));

  void _internalUpdate(RoverPosition newValue) {
    if (!newValue.hasOrientation()) return;
    _xCorrector.addValue(newValue.orientation.x);
    _yCorrector.addValue(newValue.orientation.y);
    _zCorrector.addValue(newValue.orientation.z);
    hasValue = true;
  }

  @override
  Orientation get raw => Orientation(
    x: _xCorrector.calibratedValue.clampAngle(),
    y: _yCorrector.calibratedValue.clampAngle(),
    z: _zCorrector.calibratedValue.clampAngle(),
  );
}
