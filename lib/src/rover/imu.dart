import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

import "corrector.dart";

class RoverImu extends ImuInterface {
  final _zCorrector = ErrorCorrector(maxSamples: 10, maxDeviation: 15);
  RoverImu({required super.collection});

	Orientation value = Orientation();
	
  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async {
    _zCorrector.clear();
  }

  @override
  void update(Orientation newValue) {
  //  _zCorrector.addValue(newValue.heading);
//	collection.logger.trace("Got IMU value");
//	print("Got imu");
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
