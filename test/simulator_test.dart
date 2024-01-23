import "package:burt_network/generated.dart";
import "package:test/test.dart";
import "package:burt_network/logging.dart";
import "package:autonomy/simulator.dart";

Iterable<(T1, T2)> zip<T1, T2>(List<T1> a, List<T2> b) sync* {
  for (var index = 0; index < a.length; index++) {
    yield (a[index], b[index]);
  }
}

void main() {
  test("Simulated drive works with GPS and IMU", () async { 
    Logger.level = LogLevel.info;
    final simulator = AutonomySimulator();
    final destination = GpsCoordinates();
    final result = simulator.pathfinder.getPath(destination);
    expect(simulator.gps.latitude, 0);
    expect(simulator.gps.longitude, 0);
    expect(simulator.imu.heading, 0);
    for (final (position, direction) in zip(result.path, result.directions)) {
      await simulator.drive.goDirection(direction);
      expect(simulator.gps.latitude, position.latitude);
      expect(simulator.gps.longitude, position.longitude);
    }
  });

  // Test that PathfindingInterface.getPath always returns a path and directions of equal length
}
