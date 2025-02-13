import "package:autonomy/autonomy.dart";
import "package:autonomy/constants.dart";
import "package:autonomy/interfaces.dart";

import "drive_commands.dart";

/// An implementation of [DriveInterface] that uses the rover's sensors to
/// determine its direction to move in and whether or not it has moved in its
/// desired direction/orientation
/// 
/// When this is driving, it assumes that the rover is constantly getting new sensor
/// readings, if not, this will continue moving indefinitely
class SensorDrive extends DriveInterface with RoverDriveCommands {
  /// The default period to check for a condition to become true
  static const predicateDelay = Duration(milliseconds: 10);

  /// Default constructor for SensorDrive
  SensorDrive({required super.collection, super.config});

  @override
  Future<bool> stop() async {
    stopMotors();
    return true;
  }

  /// Will periodically check for a condition to become true. This can be
  /// thought of as a "wait until", where the rover will periodically check
  /// if it has reached its desired position or orientation
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
  Future<bool> driveForward(GpsCoordinates position) async {
    collection.logger.info("Driving forward one meter");
    setThrottle(config.forwardThrottle);
    var timedOut = false;
    await waitFor(() {
      if (timedOut) return true;
      moveForward();
      return collection.gps.isNear(position, Constants.intermediateStepTolerance);
    }).timeout(
      Constants.driveGPSTimeout,
      onTimeout: () {
        collection.logger.warning(
          "GPS Drive timed out",
          body: "Failed to reach ${position.prettyPrint()} after ${Constants.driveGPSTimeout}",
        );
        timedOut = true;
      },
    );
    await stop();
    return !timedOut;
  }

  @override
  Future<bool> faceOrientation(Orientation orientation) async {
    collection.logger.info("Turning to face $orientation...");
    setThrottle(config.turnThrottle);
    await waitFor(() => _tryToFace(orientation));
    await stop();
    return true;
  }

  bool _tryToFace(Orientation orientation) {
    final current = collection.imu.heading;
    final target = orientation.heading;
    final error = (target - current).clampHalfAngle();
    if (error < 0) {
      spinRight();
    } else {
      spinLeft();
    }
    // if (error.abs() < 180) {
    //   if (current < target) {
    //     spinRight();
    //   } else {
    //     spinLeft();
    //   }
    // } else {
    //   if (current < target) {
    //     spinLeft();
    //   } else {
    //     spinRight();
    //   }
    // }
    collection.logger.trace("Current heading: $current");
    return collection.imu.isNear(orientation);
  }
}
