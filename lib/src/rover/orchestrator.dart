import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class RoverOrchestrator extends OrchestratorInterface with ValueReporter {
  List<AutonomyTransition>? currentPath;
  RoverOrchestrator({required super.collection});
  
  @override
  AutonomyData get statusMessage => AutonomyData(
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
  Message getMessage() => statusMessage;
  
  @override
  Future<void> handleGpsTask(AutonomyCommand command) async {
    final destination = command.destination;
    collection.logger.info("Got GPS Task: Go to ${destination.prettyPrint()}");
    while (!collection.gps.coordinates.isNear(destination)) {
      // Calculate a path
      collection.logger.debug("Finding a path");
      currentState = AutonomyState.PATHING;
      final path = collection.pathfinder.getPath(destination);
      currentPath = path;  // also use local variable path for promotion
      if (path == null) {
        final current = collection.gps.coordinates;
        collection.logger.error("Could not find a path", body: "No path found from ${current.prettyPrint()} to ${destination.prettyPrint()}");
        currentState = AutonomyState.NO_SOLUTION;
        currentCommand = null;
        return;
      }
      // Try to take that path
      final current = collection.gps.coordinates;
      collection.logger.trace("Found a path from ${current.prettyPrint()} to ${destination.prettyPrint()}: ${path.length} steps");
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
    collection.logger.info("Task complete");
    currentState = AutonomyState.AT_DESTINATION;
    currentCommand = null;
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
