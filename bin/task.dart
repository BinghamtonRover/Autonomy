import "package:autonomy/interfaces.dart";
import "package:autonomy/simulator.dart";
import "package:autonomy/rover.dart";
import "package:burt_network/logging.dart";

final chair = (2, 0).toGps();
final obstacles = {
  (2, 0).toGps(),
  (4, -1).toGps(),
  (4, 1).toGps(),
};
// Enter in the Dashboard: Destination = (lat=4, long=0);

void main() async {
  Logger.level = LogLevel.trace;
  final simulator = AutonomySimulator();
  simulator.pathfinder = RoverPathfinder(collection: simulator);
  simulator.orchestrator = RoverOrchestrator(collection: simulator);
  simulator.drive = DriveSimulator(collection: simulator, shouldDelay: true);
  simulator.pathfinder.obstacles.addAll(obstacles);
  await simulator.init();
  await simulator.server.waitForConnection();
}
