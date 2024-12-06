import "package:autonomy/autonomy.dart";
import "package:autonomy/interfaces.dart";

import "drive_commands.dart";

class SensorDrive extends DriveInterface with RoverDriveCommands {
  static const double maxThrottle = 0.1;
  static const double turnThrottleRover = 0.1;
  static const double turnThrottleTank = 0.35;

  static double get turnThrottle => isRover ? turnThrottleRover : turnThrottleTank;

  static const predicateDelay = Duration(milliseconds: 10);
  static const turnDelay = Duration(milliseconds: 1500);

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
  Future<void> driveForward(AutonomyAStarState state) async {
    collection.logger.info("Driving forward one meter");
    setThrottle(maxThrottle);
    moveForward();
    await waitFor(() => collection.gps.coordinates.isNear(state.position));
    await stop();
  }

  @override
  Future<void> faceDirection(CardinalDirection orientation) async {
    collection.logger.info("Turning to face $orientation...");
    setThrottle(turnThrottle);
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
    for (var i = 0; i < 16; i++) {
      setThrottle(turnThrottle);
      spinLeft();
      await Future<void>.delayed(turnDelay);
      await stop();

      for (var j = 0; j < 300; j++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        collection.logger.trace("Can see aruco? ${collection.detector.canSeeAruco()}");

        if (collection.detector.canSeeAruco()) {
          // Spin a bit more to center it
          // print("We found it!");
          // setThrottle(0.1);
          // setSpeeds(left: -1, right: 1);
          // await waitFor(() {
            // final pos = collection.video.arucoPosition;
            // collection.logger.debug("aruco is at $pos");
            // return pos > 0.2;
          //  });
          // await stop();
        return true;
      }}
    }
    return false;
  }

  @override
  Future<void> approachAruco() async {
    setThrottle(maxThrottle);
    moveForward();
    // const threshold = 0.2;
    //  await waitFor(() {
      //  final pos = collection.video.arucoSize;
      //  collection.logger.debug("It is at $pos percent");
      //  return (pos.abs() < 0.00001 && !collection.detector.canSeeAruco()) || pos >= threshold;
    //  });
    await Future<void>.delayed(const Duration(seconds: 10));
    await stop();
  }
}
