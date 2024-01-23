import "package:a_star/a_star.dart";

import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class RoverPathfinder extends PathfindingInterface {
  RoverPathfinder({required super.collection});

  final Set<GpsCoordinates> obstacleCoordinates = {};

  @override
  void recordObstacle(GpsCoordinates coordinates) => 
    obstacleCoordinates.add(coordinates);

  @override
  List<AutonomyTransition>? getPath(GpsCoordinates destination) {
    final state = AutonomyAStarState(
      position: collection.gps.coordinates,
      orientation: collection.imu.orientation,
      goal: destination,
    )..finalize();
    final result = aStar(state);
    if (result == null) return null;
    final transitions = result.reconstructPath().toList().cast<AutonomyTransition>();
    return transitions;
  }
}
