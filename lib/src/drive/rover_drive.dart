import "package:autonomy/src/drive/sensor_drive.dart";
import "package:autonomy/src/drive/timed_drive.dart";
import "package:burt_network/burt_network.dart";
import "package:autonomy/interfaces.dart";

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
  Future<void> faceNorth() async {
    if (useImu) {
      await sensorDrive.faceNorth();
    } else {
      await timedDrive.faceNorth();
      await simDrive?.faceNorth();
    }
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
  Future<void> goForward() async {
    if (useGps) {
      await sensorDrive.goForward();
    } else {
      await timedDrive.goForward();
      await simDrive?.goForward();
    }
  }

  @override
  Future<void> turnLeft() async {
    if (useImu) {
      await sensorDrive.turnLeft();
    } else {
      await timedDrive.turnLeft();
      await simDrive?.turnLeft();
    }
  }

  @override
  Future<void> turnRight() async {
    if (useImu) {
      await sensorDrive.turnRight();
    } else {
      await timedDrive.turnRight();
      await simDrive?.turnRight();
    }
  }

  @override
  Future<void> turnQuarterLeft() async {
    if (useImu) {
      await sensorDrive.turnQuarterLeft();
    } else {
      await timedDrive.turnQuarterLeft();
      await simDrive?.turnQuarterLeft();
    }
  }

  @override
  Future<void> turnQuarterRight() async {
    if (useImu) {
      await sensorDrive.turnQuarterRight();
    } else {
      await timedDrive.turnQuarterRight();
      await simDrive?.turnQuarterRight();
    }
  }
}
