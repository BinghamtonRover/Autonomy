import "package:autonomy/interfaces.dart";

import "../utils/motors.dart";

class TimedDrive extends DriveInterface with RoverMotors {
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
    await goForward();
  }
  
  @override
  Future<void> turn(AutonomyAStarState state) async {
    switch (state.direction) {
      case DriveDirection.forward:
        break;
      case DriveDirection.left:
        await turnLeft();
      case DriveDirection.right:
        await turnRight();
      case DriveDirection.forwardLeft:
        await turnQuarterLeft();
      case DriveDirection.forwardRight:
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

  Future<void> goForward() async {
    setThrottle(maxThrottle);
    setSpeeds(left: 1, right: 1);
    await Future<void>.delayed(oneMeterDelay);
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
}
