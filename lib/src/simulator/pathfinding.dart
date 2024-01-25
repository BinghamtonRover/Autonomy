import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class PathfindingSimulator extends PathfindingInterface {
  PathfindingSimulator({required super.collection});

  @override
  List<AutonomyTransition> getPath(GpsCoordinates destination) => [
    AutonomyTransition.simulated(position: (0, 0).toGps(), orientation: OrientationUtils.north, direction: DriveDirection.DRIVE_DIRECTION_RIGHT, collection: collection),
    AutonomyTransition.simulated(position: (0, 0).toGps(), orientation: OrientationUtils.east, direction: DriveDirection.DRIVE_DIRECTION_FORWARD, collection: collection),
    AutonomyTransition.simulated(position: (0, 1).toGps(), orientation: OrientationUtils.east, direction: DriveDirection.DRIVE_DIRECTION_FORWARD, collection: collection),
    AutonomyTransition.simulated(position: (0, 2).toGps(), orientation: OrientationUtils.east, direction: DriveDirection.DRIVE_DIRECTION_LEFT, collection: collection),
    AutonomyTransition.simulated(position: (0, 2).toGps(), orientation: OrientationUtils.north, direction: DriveDirection.DRIVE_DIRECTION_FORWARD, collection: collection),
    AutonomyTransition.simulated(position: (1, 2).toGps(), orientation: OrientationUtils.north, direction: DriveDirection.DRIVE_DIRECTION_FORWARD, collection: collection),
    AutonomyTransition.simulated(position: (2, 2).toGps(), orientation: OrientationUtils.north, direction: DriveDirection.DRIVE_DIRECTION_LEFT, collection: collection),
    AutonomyTransition.simulated(position: (2, 2).toGps(), orientation: OrientationUtils.west, direction: DriveDirection.DRIVE_DIRECTION_FORWARD, collection: collection),
    AutonomyTransition.simulated(position: (2, 1).toGps(), orientation: OrientationUtils.west, direction: DriveDirection.DRIVE_DIRECTION_RIGHT, collection: collection),
    AutonomyTransition.simulated(position: (2, 1).toGps(), orientation: OrientationUtils.north, direction: DriveDirection.DRIVE_DIRECTION_FORWARD, collection: collection),
  ];

  @override
  void recordObstacle(GpsCoordinates coordinates) { }

  @override
  bool isObstacle(GpsCoordinates coordinates) => false;
}
