import "package:autonomy/autonomy.dart";
import "package:autonomy/interfaces.dart";
import "package:autonomy/src/rover/drive/motors.dart";
import "package:burt_network/generated.dart";

class SensorDrive extends DriveInterface with RoverMotors {
  static const double maxThrottle = 0.1;
  static const double turnThrottle = 0.1;
  static const predicateDelay = Duration(milliseconds: 100);
  
  SensorDrive({required super.collection});

  @override
  Future<void> stop() async {
    setThrottle(0);
    setSpeeds(left: 0, right: 0);
  }

  Future<void> waitFor(bool Function() predicate) async {
    while (!predicate()) {
//	collection.logger.debug("Next turning loop");
      collection.imu.hasValue = false;
      setThrottle(maxThrottle);
      setSpeeds(left: -1, right: 1);
      await Future<void>.delayed(predicateDelay);
	if (!collection.imu.hasValue) {
//	collection.logger.trace("IMU has value: ${collection.imu.hasValue}");
	  await stop();
//		collection.logger.warning("Checked for IMU value but didn't find it");
	}
      await collection.imu.waitForValue();
    }
  }

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }

  @override
  Future<void> goForward() async {
    final orientation = collection.imu.orientation;
    final currentCoordinates = collection.gps.coordinates;
    final destination = currentCoordinates.goForward(orientation!);
    
    setThrottle(maxThrottle);
    setSpeeds(left: 1, right: 1);
    await waitFor(() => collection.gps.coordinates.isNear(destination));
    await stop();
  }

  @override
  Future<void> faceNorth() async {
    collection.logger.info("Turning to face north...");
    setThrottle(turnThrottle);
    setSpeeds(left: -1, right: 1);
    await waitFor(() {
      collection.logger.trace("Current heading: ${collection.imu.heading}");
      return collection.imu.raw.isNear(0);
    });
    await stop();
  }

  @override
  Future<void> faceDirection(DriveOrientation orientation) async {
    collection.logger.info("Turning to face $orientation...");
    setThrottle(turnThrottle);
    setSpeeds(left: -1, right: 1);
    await waitFor(() {
      collection.logger.trace("Current heading: ${collection.imu.heading}");
      return collection.imu.raw.isNear(orientation.angle.toDouble());
    });
    await stop();
    await super.faceDirection(orientation);
  }

  @override
  Future<void> turnLeft() async {
	if (collection.imu.orientation == null) {
		await faceNorth();
		await faceDirection(this.orientation);
	}
    final orientation = collection.imu.orientation;
    final destination = orientation!.turnLeft();  // do NOT clamp!
    setThrottle(maxThrottle);
    setSpeeds(left: -1, right: 1);
    await waitFor(() => collection.imu.orientation == destination); 
    await stop();
	this.orientation = this.orientation.turnLeft();

  }

  @override
  Future<void> turnRight() async {
    // TODO: Allow corrective turns
        if (collection.imu.orientation == null) {
                await faceNorth();
                await faceDirection(this.orientation);
        }
    final orientation = collection.imu.orientation;
    final destination = orientation!.turnRight();  // do NOT clamp!
    setThrottle(maxThrottle);
    setSpeeds(left: 1, right: -1);
    await waitFor(() => collection.imu.orientation == destination); 
    await stop();
	this.orientation = this.orientation.turnRight();
  }

  @override
  Future<bool> spinForAruco() async {
    for (var i = 0; i < 4; i++) {
      await turnLeft();
      if (collection.detector.canSeeAruco()) {
        // Spin a bit more to center it
        setThrottle(0.1);
        setSpeeds(left: -1, right: 1);
        await waitFor(() => collection.video.arucoPosition.abs() < 0.3);
        await stop();
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> approachAruco() async {
    setThrottle(maxThrottle);
    setSpeeds(left: 1, right: 1);
    const threshold = 0.2;
    await waitFor(() => collection.video.arucoSize >= threshold);
    await stop();
  }
}
