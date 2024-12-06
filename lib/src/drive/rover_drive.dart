import "package:burt_network/burt_network.dart";
import "package:autonomy/interfaces.dart";
import "package:autonomy/rover.dart";

import "sensor_drive.dart";
import "timed_drive.dart";

/// A helper class to send drive commands to the rover with a simpler API.
class RoverDrive extends DriveInterface {
  final bool useGps;
  final bool useImu;

  final DriveInterface sensorDrive;
  final DriveInterface timedDrive;
  final DriveInterface? simDrive;

  RoverDrive({
    required super.collection,
    DriveInterface? sensorDrive,
    DriveInterface? timedDrive,
    this.simDrive,
    this.useGps = true,
    this.useImu = true,
  })  : sensorDrive = sensorDrive ?? SensorDrive(collection: collection),
        timedDrive = timedDrive ?? TimedDrive(collection: collection);

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
    if (simDrive != null) {
      result &= await simDrive!.init();
    }

    return result;
  }

  /// Stops the rover from driving.
  @override
  Future<void> dispose() => Future.wait([
        sensorDrive.dispose(),
        timedDrive.dispose(),
        if (simDrive != null) simDrive!.dispose(),
      ]);

  /// Sets the angle of the front camera.
  void setCameraAngle({required double swivel, required double tilt}) {
    collection.logger.trace("Setting camera angles to $swivel (swivel) and $tilt (tilt)");
    final command = DriveCommand(frontSwivel: swivel, frontTilt: tilt);
    collection.server.sendCommand(command);
  }

  @override
  Future<void> stop() async {
    await sensorDrive.stop();
    await timedDrive.stop();
    await simDrive?.stop();
  }

  @override
  Future<bool> spinForAruco() => sensorDrive.spinForAruco();

  @override
  Future<void> approachAruco() => sensorDrive.approachAruco();

  @override
  Future<void> faceDirection(DriveOrientation orientation) async {
    if (useImu) {
      await sensorDrive.faceDirection(orientation);
    } else {
      await timedDrive.faceDirection(orientation);
      await simDrive?.faceDirection(orientation);
    }
    await super.faceDirection(orientation);
  }

  @override
  Future<void> driveForward(AutonomyAStarState state) async {
    if (useGps) {
      await sensorDrive.driveForward(state);
    } else {
      await timedDrive.driveForward(state);
      await simDrive?.driveForward(state);
    }
  }
}
