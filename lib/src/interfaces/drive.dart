import "package:burt_network/generated.dart";

import "package:autonomy/interfaces.dart";

abstract class DriveInterface extends Service {
  AutonomyInterface collection;
  DriveInterface({required this.collection});

  Future<void> goDirection(DriveDirection direction) async => switch (direction) {
    DriveDirection.DRIVE_DIRECTION_FORWARD => await goForward(),
    DriveDirection.DRIVE_DIRECTION_LEFT => await turnLeft(),
    DriveDirection.DRIVE_DIRECTION_RIGHT => await turnRight(),
    DriveDirection.DRIVE_DIRECTION_STOP => await stop(),
    _ => null,
  };
  
  Future<void> goForward();
  Future<void> turnLeft();
  Future<void> turnRight();
  Future<void> stop();

  Future<void> followPath(List<AutonomyTransition> path) async {
    for (final transition in path) {
      await goDirection(transition.direction);
    }
  }
}
