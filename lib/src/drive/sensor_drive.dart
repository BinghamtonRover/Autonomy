import "package:autonomy/autonomy.dart";
import "package:autonomy/interfaces.dart";

import "drive_commands.dart";

class SensorDrive extends DriveInterface with RoverDriveCommands {
  static const predicateDelay = Duration(milliseconds: 10);

  SensorDrive({required super.collection});

  @override
  Future<void> stop() async => stopMotors();

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
  Future<void> driveForward(GpsCoordinates position) async {
    collection.logger.info("Driving forward one meter");
    setThrottle(config.forwardThrottle);
    moveForward();
    await waitFor(() => collection.gps.isNear(position));
    await stop();
  }

  @override
  Future<void> faceDirection(CardinalDirection orientation) async {
    collection.logger.info("Turning to face $orientation...");
    setThrottle(config.turnThrottle);
    await waitFor(() => _tryToFace(orientation));
    await stop();
  }

  bool _tryToFace(CardinalDirection orientation) {
    final current = collection.imu.heading;
    final target = orientation.angle;
    if ((current - target).abs() < 180) {
      if (current < target) {
        spinRight();
      } else {
        spinLeft();
      }
    } else {
      if (current < target) {
        spinLeft();
      } else {
        spinRight();
      }
    }
    collection.logger.trace("Current heading: $current");
    return collection.imu.isNear(orientation);
  }

  @override
  Future<bool> spinForAruco() async {
    setThrottle(config.turnThrottle);
    spinLeft();
    final result = await waitFor(() => collection.detector.canSeeAruco())
      .then((_) => true)
      .timeout(config.turnDelay * 4, onTimeout: () => false);
    await stop();
    return result;
  }

  @override
  Future<void> approachAruco() async {
    const sizeThreshold = 0.2;
    const epsilon = 0.00001;
    setThrottle(config.forwardThrottle);
    moveForward();
    await waitFor(() {
      final size = collection.video.arucoSize;
      collection.logger.trace("The Aruco tag is at $size percent");
      return (size.abs() < epsilon && !collection.detector.canSeeAruco()) || size >= sizeThreshold;
    }).timeout(config.oneMeterDelay * 5);
    await stop();
  }
}
