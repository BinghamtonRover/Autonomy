import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class RoverOrchestrator extends OrchestratorInterface with ValueReporter {
  List<AutonomyTransition>? currentPath;
  RoverOrchestrator({required super.collection});
  
  @override
  AutonomyData getMessage() => AutonomyData(
    destination: currentCommand?.destination,
    state: currentState,
    obstacles: collection.pathfinder.obstacles,
    path: [
      for (final transition in currentPath ?? <AutonomyTransition>[])
        transition.position,
    ],
    task: currentCommand?.task,
    crash: false,  // TODO: Investigate if this is used and how to use it better
  );
  
  @override
  Future<void> handleGpsTask(AutonomyCommand command) async {
    final destination = command.destination;
    collection.logger.info("Got GPS Task: Go to ${destination.prettyPrint()}");
    while (!collection.gps.coordinates.isNear(destination)) {
      // Calculate a path
      collection.logger.debug("Finding a path");
      currentState = AutonomyState.PATHING;
      final path = collection.pathfinder.getPath(destination);
      if (path == null) {
        currentState = AutonomyState.NO_SOLUTION;
        final current = collection.gps.coordinates;
        collection.logger.error("Could not find a path from ${current.prettyPrint()} to ${destination.prettyPrint()}");
        await collection.restart();
        return;
      }
      // Try to take that path
      currentState = AutonomyState.DRIVING;
      for (final transition in path) {
        await collection.drive.goDirection(transition.direction);
        final foundObstacle = collection.detector.findObstacles();
        if (foundObstacle) {
          collection.logger.debug("Found an obstacle. Recalculating path..."); 
          break;  // calculate a new path
        }
      }
    }
  }

  @override
  Future<void> handleArucoTask(AutonomyCommand command) async {

  }

  @override
  Future<void> handleHammerTask(AutonomyCommand command) async {

  }

  @override
  Future<void> handleBottleTask(AutonomyCommand command) async {

  }
}
