import "package:test/test.dart";
import "package:burt_network/logging.dart";
import "package:autonomy/simulator.dart";

void main() {
  test("Simulated drive works with GPS and IMU", () async { 
    Logger.level = LogLevel.info;
    final simulator = AutonomySimulator();
    expect(simulator.gps.latitude, 0);
    expect(simulator.gps.longitude, 0);
    expect(simulator.imu.heading, 0);
    await simulator.testDrive(delay: false);
    expect(simulator.gps.latitude, 3);
    expect(simulator.gps.longitude, 1);
    expect(simulator.imu.heading, 0);
  });
}
