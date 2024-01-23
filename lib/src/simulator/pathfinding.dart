import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

extension on (num, num) {
  GpsCoordinates toGps() => GpsCoordinates(latitude: $1.toDouble(), longitude: $2.toDouble());
}

class PathfindingSimulator extends PathfindingInterface {
  PathfindingSimulator({required super.collection});

  @override
  PathfindingResult getPath(GpsCoordinates destination) => PathfindingResult(
    path: [
      (0, 0).toGps(),
      (0, 1).toGps(),
      (0, 2).toGps(),
      (0, 2).toGps(),
      (1, 2).toGps(),
      (2, 2).toGps(),
      (2, 2).toGps(),
      (2, 1).toGps(),
      (2, 1).toGps(),
      (3, 1).toGps(),
    ], 
    directions: [
      DriveDirection.DRIVE_DIRECTION_RIGHT,
      DriveDirection.DRIVE_DIRECTION_FORWARD,
      DriveDirection.DRIVE_DIRECTION_FORWARD,
      DriveDirection.DRIVE_DIRECTION_LEFT,
      DriveDirection.DRIVE_DIRECTION_FORWARD,
      DriveDirection.DRIVE_DIRECTION_FORWARD,
      DriveDirection.DRIVE_DIRECTION_LEFT,
      DriveDirection.DRIVE_DIRECTION_FORWARD,
      DriveDirection.DRIVE_DIRECTION_RIGHT,
      DriveDirection.DRIVE_DIRECTION_FORWARD,
    ],
  );
}
