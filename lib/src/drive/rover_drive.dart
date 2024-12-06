import "package:autonomy/interfaces.dart";
import "package:autonomy/rover.dart";

import "sensor_drive.dart";
import "timed_drive.dart";
import "sim_drive.dart";

/// A helper class to send drive commands to the rover with a simpler API.
class RoverDrive extends DriveInterface {
  final bool useGps;
  final bool useImu;

  late final sensorDrive = SensorDrive(collection: collection);
  late final timedDrive = TimedDrive(collection: collection);
  late final simDrive = DriveSimulator(collection: collection);

  RoverDrive({
    required super.collection,
    this.useGps = true,
    this.useImu = true,
  });

  /// Initializes the rover's drive subsystems.
  @override
  Future<bool> init() async {
    if (!useImu && collection.imu is RoverImu) {
      collection.logger.critical(
        "Cannot use Rover IMU with simulated turning",
        body: "Set useImu to true, or use the simulated IMU",
      );
      return false;
    }
    if (!useGps && collection.imu is RoverGps) {
      collection.logger.critical(
        "Cannot use Rover GPS with simulated driving",
        body: "Set useGps to true, or use the simulated GPS",
      );
      return false;
    }

    var result = true;
    result &= await sensorDrive.init();
    result &= await timedDrive.init();
    result &= await simDrive.init();
    return result;
  }

  /// Stops the rover from driving.
  @override
  Future<void> dispose() async {
    await sensorDrive.dispose();
    await timedDrive.dispose();
    await simDrive.dispose();
  }

  @override
  Future<void> stop() async {
    await sensorDrive.stop();
    await timedDrive.stop();
    await simDrive.stop();
  }

  @override
  Future<bool> spinForAruco() => sensorDrive.spinForAruco();

  @override
  Future<void> approachAruco() => sensorDrive.approachAruco();

  @override
  Future<void> faceDirection(CardinalDirection orientation) async {
    if (useImu) {
      await sensorDrive.faceDirection(orientation);
    } else {
      await timedDrive.faceDirection(orientation);
      await simDrive.faceDirection(orientation);
    }
  }

  @override
  Future<void> driveForward(AutonomyAStarState state) async {
    if (useGps) {
      await sensorDrive.driveForward(state);
    } else {
      await timedDrive.driveForward(state);
      await simDrive.driveForward(state);
    }
  }
}
