import "package:autonomy/autonomy.dart";
import "package:autonomy/interfaces.dart";

import "drive_commands.dart";

class SensorDrive extends DriveInterface with RoverDriveCommands {
  static const double maxThrottle = 0.1;
  static const double turnThrottleRover = 0.1;
  static const double turnThrottleTank = 0.35;

  static double get turnThrottle => isRover ? turnThrottleRover : turnThrottleTank;

  static const predicateDelay = Duration(milliseconds: 100);
  static const defaultFeedbackPeriod = Duration(milliseconds: 10);
  static const turnDelay = Duration(milliseconds: 1500);

  SensorDrive({required super.collection});

  @override
  Future<void> stop() async {
    setThrottle(0);
    setSpeeds(left: 0, right: 0);
  }

  Future<void> waitFor(bool Function() predicate, [Duration period = predicateDelay]) async {
    while (!predicate()) {
      await Future<void>.delayed(period);
      await collection.imu.waitForValue();
    }
  }

  Future<void> runFeedback(bool Function() completed, [Duration period = defaultFeedbackPeriod]) async {
    while (!completed()) {
      await Future<void>.delayed(period);
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
    setSpeeds(left: 1, right: 1);
    await waitFor(() => collection.gps.coordinates.isNear(state.position));
    await stop();
  }

  @override
  Future<void> faceDirection(CardinalDirection orientation) async {
    collection.logger.info("Turning to face $orientation...");
    setThrottle(turnThrottle);
    await runFeedback(
      () {
        var delta = orientation.angle.toDouble() - collection.imu.raw.z;
        if (delta < -180) {
          delta += 360;
        } else if (delta > 180) {
          delta -= 360;
        }

        if (delta < 0) {
          setSpeeds(left: 1, right: -1);
        } else {
          setSpeeds(left: -1, right: 1);
        }
        collection.logger.trace("Current heading: ${collection.imu.heading}");
        return collection.imu.raw.isNear(orientation.angle.toDouble());
      },
    );
    await stop();
  }

  @override
  Future<bool> spinForAruco() async {
    for (var i = 0; i < 16; i++) {
      setThrottle(turnThrottle);
      setSpeeds(left: -1, right: 1);
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
    setSpeeds(left: 1, right: 1);
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
