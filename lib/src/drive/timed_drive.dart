import "dart:math";

import "package:autonomy/interfaces.dart";

import "drive_commands.dart";

class TimedDrive extends DriveInterface with RoverDriveCommands {
  static const forwardThrottleTank = 0.3;
  static const turnThrottleTank = 0.35;

  static const forwardThrottleRover = 0.1;
  static const turnThrottleRover = 0.1;

  static const oneMeterDelayRover = Duration(milliseconds: 5500);
  static const turnDelayRover = Duration(milliseconds: 4500);

  static const oneMeterDelayTank = Duration(milliseconds: 2000);
  static const turnDelayTank = Duration(milliseconds: 1000);

  static double get maxThrottle => isRover ? forwardThrottleRover : forwardThrottleTank;
  static double get turnThrottle => isRover ? turnThrottleRover : turnThrottleTank;

  static Duration get oneMeterDelay => isRover ? oneMeterDelayRover : oneMeterDelayTank;
  static Duration get turnDelay => isRover ? turnDelayRover : turnDelayTank;

  TimedDrive({required super.collection});

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }

  @override
  Future<void> driveForward(AutonomyAStarState state) async {
    await goForward(collection.imu.nearest.isPerpendicular ? 1 : sqrt2);
  }

  @override
  Future<void> turn(AutonomyAStarState state) async {
    switch (state.instruction) {
      case DriveDirection.forward:
        break;
      case DriveDirection.left:
        await turnLeft();
      case DriveDirection.right:
        await turnRight();
      case DriveDirection.quarterLeft:
        await turnQuarterLeft();
      case DriveDirection.quarterRight:
        await turnQuarterRight();
      case DriveDirection.stop:
        break;
    }
  }

  @override
  Future<void> stop() async {
    setThrottle(0);
    setSpeeds(left: 0, right: 0);
  }

  Future<void> goForward([double distance = 1]) async {
    collection.logger.info("Driving forward $distance meters");
    setThrottle(maxThrottle);
    setSpeeds(left: 1, right: 1);
    await Future<void>.delayed(oneMeterDelay * distance);
    await stop();
  }

  Future<void> turnLeft() async {
    setThrottle(turnThrottle);
    setSpeeds(left: -1, right: 1);
    await Future<void>.delayed(turnDelay);
    await stop();
  }

  Future<void> turnRight() async {
    setThrottle(turnThrottle);
    setSpeeds(left: 1, right: -1);
    await Future<void>.delayed(turnDelay);
    await stop();
  }

  Future<void> turnQuarterLeft() async {
    setThrottle(turnThrottle);
    setSpeeds(left: -1, right: 1);
    await Future<void>.delayed(turnDelay * 0.5);
    await stop();
  }

  Future<void> turnQuarterRight() async {
    setThrottle(turnThrottle);
    setSpeeds(left: 1, right: -1);
    await Future<void>.delayed(turnDelay * 0.5);
    await stop();
  }

  @override
  Future<void> faceDirection(CardinalDirection orientation) =>
    // TODO: Implement this
    throw UnimplementedError("Cannot face any arbitrary direction using TimedDrive");
}
