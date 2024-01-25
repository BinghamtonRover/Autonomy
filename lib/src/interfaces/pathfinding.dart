import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

abstract class PathfindingInterface extends Service {
  final AutonomyInterface collection;
  PathfindingInterface({required this.collection});

  List<AutonomyTransition>? getPath(GpsCoordinates destination);
  void recordObstacle(GpsCoordinates coordinates);
  bool isObstacle(GpsCoordinates coordinates);
}
