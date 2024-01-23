import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class PathfindingResult {
  final List<GpsCoordinates> path;
  final List<DriveDirection> directions;
  const PathfindingResult({
    required this.path,
    required this.directions,
  });
}

abstract class PathfindingInterface extends Service {
  final AutonomyInterface collection;
  PathfindingInterface({required this.collection});

  PathfindingResult getPath(GpsCoordinates destination);
}
