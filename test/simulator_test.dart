import "package:autonomy/src/rover/gps.dart";
import "package:test/test.dart";
import "package:burt_network/generated.dart";
import "package:burt_network/logging.dart";

import "package:autonomy/interfaces.dart";
import "package:autonomy/rover.dart";
import "package:autonomy/simulator.dart";

void main() {
  test("Simulator can be restarted", () async { 
    final simulator = AutonomySimulator();
    await simulator.init();
    await simulator.restart();
    await simulator.dispose();
  });
  
  test("Simulated drive test with simulated GPS", () async {
    Logger.level = LogLevel.info;
    final simulator = AutonomySimulator();
    expect(simulator.gps.latitude, 0);
    expect(simulator.gps.longitude, 0);
    expect(simulator.imu.heading, 0);
    // Turning left takes you +90 degrees
    await simulator.drive.turnLeft();
    expect(simulator.imu.heading, 90);
    // Turning right takes you -90 degrees
    await simulator.drive.turnRight();
    expect(simulator.imu.heading, 0);
    // Going straight takes you 1 cell forward
    await simulator.drive.goForward();
    expect(simulator.gps.latitude, 1);
    expect(simulator.gps.longitude, 0);
    expect(simulator.imu.heading, 0);
    // Going forward at 90 degrees
    await simulator.drive.turnLeft();
    await simulator.drive.goForward();
    expect(simulator.gps.latitude, 1);
    expect(simulator.gps.longitude, -1);
    expect(simulator.imu.heading, 90);   
    // Going forward at 180 degrees
    await simulator.drive.turnLeft();
    await simulator.drive.goForward();
    expect(simulator.gps.latitude, 0);
    expect(simulator.gps.longitude, -1);
    expect(simulator.imu.heading, 180);   
    // Going forward at 270 degrees
    await simulator.drive.turnLeft();
    await simulator.drive.goForward();
    expect(simulator.gps.latitude, 0);
    expect(simulator.gps.longitude, 0);
    expect(simulator.imu.heading, 270);   
    // 4 lefts go back to north
    await simulator.drive.turnLeft();
    expect(simulator.imu.heading, 0);
  });

  test("Real pathfinding is coherent", () async { 
    Logger.level = LogLevel.info;
    final simulator = AutonomySimulator();
    simulator.pathfinder = RoverPathfinder(collection: simulator);
    await testPath(simulator);
  });

  test("Simulated pathfinding is coherent", () async { 
    Logger.level = LogLevel.info;
    final simulator = AutonomySimulator();
    await testPath(simulator);
  });

  test("Following path gets to the end", () async { 
    Logger.level = LogLevel.info;
    final simulator = AutonomySimulator();
    simulator.pathfinder = RoverPathfinder(collection: simulator);
    final destination = (5, 5).toGps();
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNotNull); if (path == null) return;
    expect(simulator.gps.latitude, 0);
    expect(simulator.gps.longitude, 0);
    await simulator.drive.followPath(path);
    expect(simulator.gps.latitude, destination.latitude);
    expect(simulator.gps.longitude, destination.longitude);
  });

  test("Path avoids obstacles but reaches the goal", () async {
    Logger.level = LogLevel.info;
    final simulator = AutonomySimulator();
    simulator.pathfinder = RoverPathfinder(collection: simulator);
    final destination = GpsCoordinates(latitude: 5, longitude: 5);
    final obstacles = <GpsCoordinates>{
      (1, 0).toGps(),
      (1, 1).toGps(),
      (2, 0).toGps(),
      (2, 1).toGps(),
      (3, 3).toGps(),
    };
    for (final obstacle in obstacles) {
      simulator.pathfinder.recordObstacle(obstacle);
    }
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNotNull); if (path == null) return;
    expect(path, isNotEmpty);
    for (final step in path) {
      expect(obstacles.contains(step.position), false);
    }
    await simulator.drive.followPath(path);
    expect(simulator.gps.latitude, destination.latitude);
    expect(simulator.gps.longitude, destination.longitude);
  });

  test("Impossible paths are reported", () async {
    final simulator = AutonomySimulator();
    simulator.pathfinder = RoverPathfinder(collection: simulator);
    final destination = (5, 5).toGps();
    final obstacles = {
      (1, -1).toGps(),  (1, 0).toGps(),  (1, 1).toGps(),
      (0, -1).toGps(),   /* Rover */     (0, 1).toGps(),
      (-1, -1).toGps(), (-1, 0).toGps(), (-1, 1).toGps(),
    };
    for (final obstacle in obstacles) {
      simulator.pathfinder.recordObstacle(obstacle);
    }
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNull);
  });

  test("GPS Error is appropriate", () async {
    // TODO: Measure the actual error here
    final simulator = AutonomySimulator();
    final simulatedGps = GpsSimulator(collection: simulator, maxError: 0.00003);
    final realGps = RoverGps(collection: simulator);
    final origin = GpsCoordinates(latitude: 0, longitude: 0);
    simulatedGps.update(origin);
    for (var i = 0; i < 5; i++) {
      final coordinates = simulatedGps.coordinates;
      realGps.update(coordinates);
    }
    realGps.update(GpsCoordinates(latitude: 100, longitude: 100));
    expect(realGps.coordinates.isNear(origin), isTrue);
  });
}

Future<void> testPath(AutonomyInterface simulator) async {
  final destination = GpsCoordinates(latitude: 5, longitude: 5);
  final result = simulator.pathfinder.getPath(destination);
  expect(simulator.gps.latitude, 0);
  expect(simulator.gps.longitude, 0);
  expect(simulator.imu.heading, 0);
  expect(result, isNotNull); if (result == null) return;
  expect(result, isNotEmpty);
  AutonomyTransition transition;
  for (transition in result) {
    simulator.logger.debug(transition.toString());
    simulator.logger.trace("  From: ${simulator.gps.coordinates.prettyPrint()}");
    expect(simulator.gps.latitude, transition.position.latitude);
    expect(simulator.gps.longitude, transition.position.longitude);
    expect(simulator.imu.heading, transition.orientation.heading);
    await simulator.drive.goDirection(transition.direction);
    simulator.logger.trace("  To: ${simulator.gps.coordinates.prettyPrint()}");
  }
}
