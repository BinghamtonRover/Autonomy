import "package:test/test.dart";

import "package:burt_network/protobuf.dart";
import "package:burt_network/logging.dart";

import "package:autonomy/interfaces.dart";
import "package:autonomy/rover.dart";
import "package:autonomy/simulator.dart";

void main() => group("[Rover]", tags: ["rover"], () {
  test("Can be restarted", () async {
    Logger.level = LogLevel.off;
    final rover = RoverAutonomy();
    await rover.init();
    await rover.restart();
    await rover.dispose();
  });

  test("Real pathfinding is coherent", () async {
    Logger.level = LogLevel.off;
    final simulator = AutonomySimulator();
    simulator.pathfinder = RoverPathfinder(collection: simulator);
    await testPath(simulator);
    simulator.gps.update((lat: 0, long: 0).toGps());
    simulator.imu.update(Orientation());
    await testPath2(simulator);
    await simulator.dispose();
  });

  test("Waits for sensor data", () async {
    final rover = RoverAutonomy();
    final position = (lat: 5, long: 5).toGps();
    final orientation = Orientation();
    final data = VideoData();

    await rover.init();

    expect(rover.hasValue, isFalse);
    expect(rover.gps.hasValue, isFalse);
    rover.gps.forceUpdate(position);
    expect(rover.gps.hasValue, isTrue);
    expect(rover.hasValue, isFalse);

    expect(rover.hasValue, isFalse);
    expect(rover.imu.hasValue, isFalse);
    rover.imu.forceUpdate(orientation);
    expect(rover.imu.hasValue, isTrue);
    expect(rover.hasValue, isFalse);

    expect(rover.hasValue, isFalse);
    expect(rover.video.hasValue, isFalse);
    rover.video.updateFrame(data);
    expect(rover.video.hasValue, isTrue);
    expect(rover.hasValue, isTrue);

    await rover.dispose();
  });
});

Future<void> testPath(AutonomyInterface simulator) async {
  final destination = (lat: 5, long: 5).toGps();
  final result = simulator.pathfinder.getPath(destination);
  expect(simulator.gps.latitude, 0);
  expect(simulator.gps.longitude, 0);
  expect(simulator.imu.heading, 0);
  expect(result, isNotNull); if (result == null) return;
  expect(result, isNotEmpty);
  for (final transition in result) {
    simulator.logger.trace("  From: ${simulator.gps.coordinates.prettyPrint()} facing ${simulator.imu.heading}");
    simulator.logger.debug("  $transition");
    await simulator.drive.driveState(transition);
    expect(simulator.gps.isNear(transition.position), isTrue);
    simulator.logger.trace("New orientation: ${simulator.imu.heading}");
    simulator.logger.trace("Expected orientation: ${transition.orientation}");
    expect(simulator.imu.nearest, transition.orientation);
  }
}

Future<void> testPath2(AutonomyInterface simulator) async {
  // Logger.level = LogLevel.all;
  final destination = (lat: 4, long: 0).toGps();
  simulator.pathfinder.recordObstacle((lat: 2, long: 0).toGps());
  simulator.pathfinder.recordObstacle((lat: 4, long: -1).toGps());
  simulator.pathfinder.recordObstacle((lat: 4, long: 1).toGps());
  final result = simulator.pathfinder.getPath(destination);
  expect(simulator.gps.latitude, 0);
  expect(simulator.gps.longitude, 0);
  expect(simulator.imu.heading, 0);
  expect(result, isNotNull); if (result == null) return;
  expect(result, isNotEmpty);
  for (final transition in result) {
    simulator.logger.debug(transition.toString());
    simulator.logger.trace("  From: ${simulator.gps.coordinates.prettyPrint()}");
    await simulator.drive.driveState(transition);
    expect(simulator.gps.isNear(transition.position), isTrue);
    expect(simulator.pathfinder.isObstacle(simulator.gps.coordinates), isFalse);
    expect(simulator.imu.nearest, transition.orientation);
    simulator.logger.trace("  To: ${simulator.gps.coordinates.prettyPrint()}");
  }
}
