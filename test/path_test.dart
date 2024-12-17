import "package:burt_network/burt_network.dart";
import "package:test/test.dart";

import "package:autonomy/interfaces.dart";
import "package:autonomy/rover.dart";
import "package:autonomy/simulator.dart";

extension DriveFollowPath on DriveInterface {
  Future<void> followPath(List<AutonomyAStarState> path) async {
    for (final step in path) {
      await driveState(step);
    }
  }
}

void main() => group("[Pathfinding]", tags: ["path"], () {
  setUp(() => Logger.level = LogLevel.off);
  tearDown(() => Logger.level = LogLevel.off);

  test("Simple path from (0, 0) to (5, 5) exists", () {
    final simulator = AutonomySimulator();
    final destination = (lat: 5, long: 5).toGps();
    simulator.logger.info("Each step is ${GpsUtils.north.latitude.toStringAsFixed(5)}");
    simulator.logger.info("Going to ${destination.prettyPrint()}");
    simulator.pathfinder = RoverPathfinder(collection: simulator);  
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNotNull);
  });

  test("Small paths are efficient", () {
    final oldError = GpsUtils.maxErrorMeters;
    GpsUtils.maxErrorMeters = 1;
    final simulator = AutonomySimulator();

    // Plan a path from (0, 0) to (5, 5)
    simulator.pathfinder = RoverPathfinder(collection: simulator);  
    final destination = (lat: 5, long: 5).toGps();
    simulator.logger.info("Going to ${destination.prettyPrint()}");
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNotNull); if (path == null) return;

    var turnCount = 0;
    for (final step in path) {
      if (step.instruction.isTurn) {
        turnCount++;
      }
      simulator.logger.trace(step.toString());
    }

    // start + 5 forward + 1 turn + 5 right = 12 steps
    // start + quarter turn left + 7 forward = 8 steps
    expect(turnCount, 1);
    expect(path.length, 7);
    
    GpsUtils.maxErrorMeters = oldError;
  });
  
  test("Following path gets to the end", () async { 
    final simulator = AutonomySimulator();
    final destination = (lat: 5, long: 5).toGps();
    simulator.pathfinder = RoverPathfinder(collection: simulator);
    final path = simulator.pathfinder.getPath(destination);
    
    expect(path, isNotNull); if (path == null) return;
    expect(simulator.gps.isNear(GpsCoordinates()), isTrue);

    await simulator.drive.followPath(path);
    expect(simulator.gps.isNear(destination), isTrue);

    await simulator.dispose();
  });

  test("Avoid obstacles but reach the goal", () async {
    // Logger.level = LogLevel.all;
    final simulator = AutonomySimulator();
    final destination = (lat: 5, long: 0).toGps();
    simulator.pathfinder = RoverPathfinder(collection: simulator);
    simulator.pathfinder.recordObstacle((lat: 1, long: 0).toGps());
    simulator.pathfinder.recordObstacle((lat: 2, long: 0).toGps());
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNotNull);
    if (path == null) {
      return;
    }
    expect(path, isNotEmpty);
    for (final step in path) {
      simulator.logger.trace(step.toString());
      expect(simulator.pathfinder.isObstacle(step.position), isFalse);
    }
    expect(path.length, 10, reason: "1 turn + 1 forward + 1 turn + 4 forward + 1 45 degree turn + 1 forward + 1 stop = 10 steps total");
    await simulator.drive.followPath(path);
    expect(simulator.gps.isNear(destination), isTrue);
    await simulator.dispose();
  });

  test("Stress test", () async {
    final oldError = GpsUtils.maxErrorMeters;
    final oldMoveLength = GpsUtils.moveLengthMeters;
    GpsUtils.maxErrorMeters = 1;
    // GpsUtils.moveLengthMeters = 5;
    final simulator = AutonomySimulator();
    simulator.pathfinder = RoverPathfinder(collection: simulator);
    simulator.logger.trace("Starting from ${simulator.gps.coordinates.prettyPrint()}");
    simulator.logger.trace("Each step is +/- ${GpsUtils.north.prettyPrint()}");
    final destination = (lat: 1000, long: 1000).toGps();
    simulator.logger.info("Going to ${destination.prettyPrint()}");
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNotNull);
    await simulator.dispose();
    GpsUtils.maxErrorMeters = oldError;
    GpsUtils.moveLengthMeters = oldMoveLength;
  });

  test("Impossible paths are reported", () async {
    final simulator = AutonomySimulator();
    simulator.pathfinder = RoverPathfinder(collection: simulator);
    final destination = (lat: 5, long: 5).toGps();
    final obstacles = {
      (lat: 1, long: -1).toGps(),  (lat: 1, long: 0).toGps(),  (lat: 1, long: 1).toGps(),
      (lat: 0, long: -1).toGps(),          /* Rover */         (lat: 0, long: 1).toGps(),
      (lat: -1, long: -1).toGps(), (lat: -1, long: 0).toGps(), (lat: -1, long: 1).toGps(),
    };
    for (final obstacle in obstacles) {
      simulator.pathfinder.recordObstacle(obstacle);
    }
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNull);
    await simulator.dispose();
  });
});
