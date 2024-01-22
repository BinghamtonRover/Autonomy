import "package:burt_network/generated.dart";

import "autonomy.dart";

abstract class DriveInterface {
  AutonomyInterface collection;
  DriveInterface({required this.collection});

  void handleCommand(DriveCommand command) => switch (command.direction) {
    DriveDirection.DRIVE_DIRECTION_FORWARD => goForward(),
    DriveDirection.DRIVE_DIRECTION_LEFT => turnLeft(),
    DriveDirection.DRIVE_DIRECTION_RIGHT => turnRight(),
    DriveDirection.DRIVE_DIRECTION_STOP => stop(),
    _ => null,
  };
  
  void goForward();
  void turnLeft();
  void turnRight();
  void stop();
}
