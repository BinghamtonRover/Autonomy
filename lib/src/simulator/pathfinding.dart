import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class PathfindingSimulator extends PathfindingInterface {  
  static int i = 0;
  
  PathfindingSimulator({required super.collection});

  @override
  Future<bool> init() async => true;

  @override
  List<AutonomyAStarState> getPath(GpsCoordinates destination, {bool verbose = false}) => [
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 0, long: 0).toGps(), orientation: DriveOrientation.north, direction: DriveDirection.right, collection: collection),
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 0, long: 0).toGps(), orientation: DriveOrientation.east, direction: DriveDirection.forward, collection: collection),
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 0, long: 1).toGps(), orientation: DriveOrientation.east, direction: DriveDirection.forward, collection: collection),
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 0, long: 2).toGps(), orientation: DriveOrientation.east, direction: DriveDirection.left, collection: collection),
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 0, long: 2).toGps(), orientation: DriveOrientation.north, direction: DriveDirection.forward, collection: collection),
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 1, long: 2).toGps(), orientation: DriveOrientation.north, direction: DriveDirection.forward, collection: collection),
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 2, long: 2).toGps(), orientation: DriveOrientation.north, direction: DriveDirection.left, collection: collection),
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 2, long: 2).toGps(), orientation: DriveOrientation.west, direction: DriveDirection.forward, collection: collection),
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 2, long: 1).toGps(), orientation: DriveOrientation.west, direction: DriveDirection.right, collection: collection),
    AutonomyAStarState(depth: i++, goal: (lat: 2, long: 1).toGps(), position: (lat: 2, long: 1).toGps(), orientation: DriveOrientation.north, direction: DriveDirection.forward, collection: collection),
  ];
}
