import "dart:math";

import "package:autonomy/interfaces.dart";

import "drive_commands.dart";

class TimedDrive extends DriveInterface with RoverDriveCommands {
  TimedDrive({required super.collection});

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }

  @override
  Future<void> driveForward(GpsCoordinates position) async {
    await goForward(collection.imu.nearest.isPerpendicular ? 1 : sqrt2);
  }

  @override
  Future<void> turnState(AutonomyAStarState state) async {
    switch (state.instruction) {
      case DriveDirection.left:
        await turnLeft();
      case DriveDirection.right:
        await turnRight();
      case DriveDirection.quarterLeft:
        await turnQuarterLeft();
      case DriveDirection.quarterRight:
        await turnQuarterRight();
      case DriveDirection.forward || DriveDirection.stop:
        break;
    }
  }

  @override
  Future<void> stop() async => stopMotors();

  Future<void> goForward([double distance = 1]) async {
    collection.logger.info("Driving forward $distance meters");
    setThrottle(config.forwardThrottle);
    moveForward();
    await Future<void>.delayed(config.oneMeterDelay * distance);
    await stop();
  }

  Future<void> turnLeft() async {
    setThrottle(config.turnThrottle);
    spinLeft();
    await Future<void>.delayed(config.turnDelay);
    await stop();
  }

  Future<void> turnRight() async {
    setThrottle(config.turnThrottle);
    spinRight();
    await Future<void>.delayed(config.turnDelay);
    await stop();
  }

  Future<void> turnQuarterLeft() async {
    setThrottle(config.turnThrottle);
    spinLeft();
    await Future<void>.delayed(config.turnDelay * 0.5);
    await stop();
  }

  Future<void> turnQuarterRight() async {
    setThrottle(config.turnThrottle);
    spinRight();
    await Future<void>.delayed(config.turnDelay * 0.5);
    await stop();
  }

  @override
  Future<void> faceDirection(CardinalDirection orientation) =>
    throw UnsupportedError("Cannot face any arbitrary direction using TimedDrive");
}
