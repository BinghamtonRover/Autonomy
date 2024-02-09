import "package:a_star/a_star.dart";

import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class RoverPathfinder extends PathfindingInterface {
  RoverPathfinder({required super.collection});

  @override
  List<AutonomyTransition>? getPath(GpsCoordinates destination) {
    if (isObstacle(destination)) return null;
    final state = AutonomyAStarState(
      position: collection.gps.coordinates,
      orientation: collection.imu.orientation,
      collection: collection,
      goal: destination,
    )..finalize();
    final result = aStar(state, verbose: false, limit: 10000);
    if (result == null) return null;
    final transitions = result.reconstructPath().toList().cast<AutonomyTransition>();
    return transitions;
  }
}
