import "package:autonomy/autonomy.dart";
import "package:autonomy/interfaces.dart";
import "package:autonomy/src/rover/drive/motors.dart";
import "package:burt_network/generated.dart";

class SensorDrive extends DriveInterface with RoverMotors {
  static const double maxThrottle = 0.2;
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
    setThrottle(maxThrottle);
    setSpeeds(left: -1, right: 1);
    await waitFor(() => collection.imu.raw.isNear(0));
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
    setSpeeds(left: -1, right: 1);
    await waitFor(() => collection.imu.orientation == destination); 
    await stop();
  }

  @override
  Future<bool> spinForAruco() async {
    final currentOrientation = collection.imu.heading;
    final destination = Orientation(z: currentOrientation + 180).clampHeading();
    setThrottle(maxThrottle);
    setSpeeds(left: -1, right: 1);
    await waitFor(() => collection.detector.canSeeAruco() || collection.imu.isNear(destination.heading));
    if (!collection.detector.canSeeAruco()) {
      // Spin another 180
      await waitFor(() => collection.detector.canSeeAruco() || collection.imu.isNear(destination.heading));
    }
    // Either we've done a 360, or we found an aruco
    if (collection.detector.canSeeAruco()) {
      // Spin a bit more to center it
      await waitFor(() => collection.video.arucoPosition.abs() < 0.3);
    }
    await stop();
    return collection.detector.canSeeAruco();
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
