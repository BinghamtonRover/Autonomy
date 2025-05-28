import "package:autonomy/rover.dart";
import "package:autonomy/simulator.dart";
import "package:burt_network/burt_network.dart";

void main() async {
  Logger.level = Level.debug;
  final simulator = AutonomySimulator();

  simulator.pathfinder = RoverPathfinder(collection: simulator);
  simulator.orchestrator = RoverOrchestrator(collection: simulator);
  simulator.drive = DriveSimulator(collection: simulator, shouldDelay: true);
  simulator.detector = NetworkDetector(collection: simulator);

  await simulator.init();
}
