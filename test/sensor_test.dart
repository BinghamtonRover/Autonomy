import "package:autonomy/src/rover/imu.dart";
import "package:burt_network/logging.dart";
import "package:test/test.dart";

import "package:burt_network/generated.dart";

import "package:autonomy/interfaces.dart";
import "package:autonomy/simulator.dart";
import "package:autonomy/src/rover/gps.dart";

// const gpsError = GpsUtils.gpsError;
const imuError = 5.0;
const gpsPrecision = 7;

void main() => group("[Sensors]", tags: ["sensors"], () {
  setUp(() => Logger.level = LogLevel.off);
  tearDown(() => Logger.level = LogLevel.off);

  test("GPS noise when stationary", () async {
    // Set up a simulated and real GPS, both starting at (0, 0)
    final simulator = AutonomySimulator();
    final realGps = RoverGps(collection: simulator);
    final simulatedGps = GpsSimulator(collection: simulator, maxError: GpsInterface.gpsError);
    final origin = GpsCoordinates();
    simulatedGps.update(origin);
    realGps.update(origin);
    expect(realGps.coordinates.isNear(origin), isTrue);

    // Feed many noisy signals to produce a cleaner signal.
    for (var step = 0; step < 10; step++) {
      realGps.update(simulatedGps.coordinates);
      simulator.logger.trace("New coordinate: ${realGps.coordinates.latitude.toStringAsFixed(gpsPrecision)} vs real position: ${origin.latitude.toStringAsFixed(gpsPrecision)}");
      expect(realGps.isNear(origin), isTrue);
    }

    simulator.logger.info("Final coordinates: ${realGps.coordinates.latitude}");

    // Ensure that *very* noisy readings don't affect anything.
    simulator.logger.debug("Adding 100, 100");
    simulator.gps.update(GpsCoordinates(latitude: 100, longitude: 100));
    expect(realGps.isNear(origin), isTrue);
  });

  test("IMU noise when stationary", () async {
    Logger.level = LogLevel.off;
    final simulator = AutonomySimulator();
    final simulatedImu = ImuSimulator(collection: simulator, maxError: imuError);
    final realImu = RoverImu(collection: simulator);
    final north = OrientationUtils.north;
    simulatedImu.update(north);
    for (var i = 0; i < 5; i++) {
      final orientation = simulatedImu.raw;
      realImu.update(orientation);
    }
    realImu.update(OrientationUtils.south);
    expect(realImu.isNear(OrientationUtils.north.heading), isTrue);
    await simulator.dispose();
  });

  test("GPS noise when moving", () async {
    // Set up a simulated and real GPS, both starting at (0, 0)
    Logger.level = LogLevel.off;
    final simulator = AutonomySimulator();
    final realGps = RoverGps(collection: simulator);
    final simulatedGps = GpsSimulator(collection: simulator, maxError: GpsInterface.gpsError);
    var realCoordinates = GpsCoordinates();
    simulatedGps.update(realCoordinates);
    realGps.update(realCoordinates);
    expect(realGps.coordinates.isNear(realCoordinates), isTrue);

    // For each step forward, use the noisy GPS to update the real GPS.
    for (var step = 0; step < 10; step++) {
      realCoordinates += GpsUtils.north;
      simulatedGps.update(realCoordinates);
      realGps.update(simulatedGps.coordinates);
      simulator.logger.trace("New coordinate: ${realGps.coordinates.latitude.toStringAsFixed(5)} vs real position: ${realCoordinates.latitude.toStringAsFixed(5)}");
      simulator.logger.trace("  Difference: ${(realGps.latitude - realCoordinates.latitude).abs().toStringAsFixed(5)} < ${GpsUtils.epsilonLatitude.toStringAsFixed(5)}");
      expect(realGps.isNear(realCoordinates), isTrue);
    }

    // Ensure that *very* noisy readings don't affect anything.
    simulator.logger.debug("Adding 100, 100");
    simulator.gps.update(GpsCoordinates(latitude: 100, longitude: 100));
    expect(realGps.isNear(realCoordinates), isTrue);
  });

  test("GPS latitude is set properly", () async {
    final simulator = AutonomySimulator();
    const utahLatitude = 38.406683;
    final utah = GpsCoordinates(latitude: utahLatitude);

    simulator.gps.update(utah);
    expect(simulator.hasValue, isFalse);
    expect(GpsInterface.currentLatitude, 0);
    
    await simulator.init();
    await simulator.waitForValue();
    expect(simulator.hasValue, isTrue);
    expect(GpsInterface.currentLatitude, utahLatitude);
    
    await simulator.dispose();
    GpsInterface.currentLatitude = 0;
  });
});
