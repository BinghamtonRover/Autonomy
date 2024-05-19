import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

import "corrector.dart";

class RoverImu extends ImuInterface {
  final _zCorrector = ErrorCorrector(maxSamples: 50, maxDeviation: 15);
  RoverImu({required super.collection});

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }

  @override
  void update(Orientation newValue) {
    _zCorrector.addValue(newValue.heading);
    hasValue = true;
  }

  @override
  Orientation get raw => Orientation(
    x: 0, 
    y: 0,
    z: _zCorrector.calibratedValue,
  );
}
