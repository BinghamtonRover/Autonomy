import "package:autonomy/interfaces.dart";
import "package:autonomy/rover.dart";
import "package:autonomy/simulator.dart";

import "package:burt_network/protobuf.dart";

void main() {
  GpsUtils.maxErrorMeters = 1;
  final destination = (lat: 1000, long: 1000).toGps();
  final simulator = AutonomySimulator();
  simulator.pathfinder = RoverPathfinder(collection: simulator);
  final path = simulator.pathfinder.getPath(destination);
  if (path == null) {
    simulator.logger.critical("Could not find path to ${destination.prettyPrint()}");
    return;
  }
  if (path.isEmpty) {
    simulator.logger.critical("Path was empty");
    return;
  }
  var turnCount = 0;
  for (final step in path) {
    if (step.instruction == DriveDirection.left || step.instruction == DriveDirection.right) {
      turnCount++;
    }
  }
  simulator.logger.info("Got a path with ${path.length} steps and $turnCount turn(s)");
}
