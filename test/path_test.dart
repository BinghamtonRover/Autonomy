import "package:autonomy/interfaces.dart";
import "package:autonomy/rover.dart";
import "package:autonomy/simulator.dart";
import "package:burt_network/logging.dart";
import "package:test/test.dart";

void main() => group("Pathfinding: ", tags: ["path"], () {
  setUpAll(() => Logger.level = LogLevel.off);
  tearDownAll(() => Logger.level = LogLevel.off);

  test("Simple path from (0, 0) to (5, 5) exists", () {
    final simulator = AutonomySimulator();
    simulator.pathfinder = RoverPathfinder(collection: simulator);  
    final destination = (5, 5).toGps();
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNotNull);
  });

  test("Small paths are efficient", () {
    GpsUtils.maxErrorMeters = 1;
    final simulator = AutonomySimulator();
    final oldError = GpsUtils.maxErrorMeters;

    // Plan a path from (0, 0) to (5, 5)
    simulator.pathfinder = RoverPathfinder(collection: simulator);  
    final destination = (5, 5).toGps();
    final path = simulator.pathfinder.getPath(destination);
    expect(path, isNotNull); if (path == null) return;

    // start + 5 forward + 1 turn + 5 right = 12 steps
    expect(path.length, 12);
    GpsUtils.maxErrorMeters = oldError;
  });
});
