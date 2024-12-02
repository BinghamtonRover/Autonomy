import "package:burt_network/burt_network.dart";
import "package:autonomy/interfaces.dart";

import "../math/corrector.dart";

class RoverImu extends ImuInterface {
  final _zCorrector = ErrorCorrector(maxSamples: 10, maxDeviation: 15);
  RoverImu({required super.collection});

	Orientation value = Orientation();

  @override
  Future<bool> init() async {
    collection.server.messages.onMessage(
      name: RoverPosition().messageName,
      constructor: RoverPosition.fromBuffer,
      callback: (pos) {
        if (pos.hasOrientation()) _internalUpdate(pos.orientation);
      },
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

  void _internalUpdate(Orientation newValue) {
    //  _zCorrector.addValue(newValue.heading);
    //	collection.logger.trace("Got IMU value");
    print("Got imu: ${newValue.heading}. Direction: ${collection.drive.orientation}");
    hasValue = true;
    value = newValue;
  }

  @override
  Orientation get raw => Orientation(
    x: 0,
    y: 0,
    z: value.z,
  ).clampHeading();
}
