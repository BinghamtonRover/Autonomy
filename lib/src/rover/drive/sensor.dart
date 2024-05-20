import "package:autonomy/interfaces.dart";
import "package:autonomy/src/rover/drive/motors.dart";

class SensorDrive extends DriveInterface with RoverMotors {
  static const double maxThrottle = 0.1;
  static const double turnThrottle = 0.1;
  static const predicateDelay = Duration(milliseconds: 10);
  
  SensorDrive({required super.collection});

  @override
  Future<void> stop() async {
    setThrottle(0);
    setSpeeds(left: 0, right: 0);
  }

  Future<void> waitFor(bool Function() predicate) async {
    while (!predicate()) {
      await Future<void>.delayed(predicateDelay);
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
  Future<void> turnLeft() async {
    final orientation = collection.imu.orientation!;
    final destination = orientation.turnLeft();  // do NOT clamp!
    setThrottle(maxThrottle);
    setSpeeds(left: -1, right: 1);
    await waitFor(() => collection.imu.orientation == destination); 
    await stop();
  }

  @override
  Future<void> turnRight() async {
    // TODO: Allow corrective turns
    final orientation = collection.imu.orientation;
    final destination = orientation!.turnRight();  // do NOT clamp!
    setThrottle(maxThrottle);
    setSpeeds(left: 1, right: -1);
    await waitFor(() => collection.imu.orientation == destination); 
    await stop();
  }
}
