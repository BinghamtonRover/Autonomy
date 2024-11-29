export "src/drive/rover_drive.dart";
export "src/pathfinding/rover_pathfinding.dart";
export "src/orchestrator/rover_orchestrator.dart";
export "src/drive/sensorless_drive.dart";

import "package:autonomy/interfaces.dart";
import "package:burt_network/burt_network.dart";

import "src/pathfinding/rover_pathfinding.dart";
import "src/drive/rover_drive.dart";
import "src/gps/rover_gps.dart";
import "src/imu/rover_imu.dart";
import "src/orchestrator/rover_orchestrator.dart";
import "src/video/rover_video.dart";
import "src/detector/rover_detector.dart";

/// A collection of all the different services used by the autonomy program.
class RoverAutonomy extends AutonomyInterface {
	/// A server to communicate with the dashboard and receive data from the subsystems.
	// @override late final AutonomyServer server = AutonomyServer(collection: this);
  @override late final server = RoverSocket(port: 8003, device: Device.AUTONOMY, collection: this);
	/// A helper class to handle driving the rover.
	@override late DriveInterface drive = RoverDrive(collection: this);
  @override late GpsInterface gps = RoverGps(collection: this);
  @override late ImuInterface imu = RoverImu(collection: this);
  @override late final logger = BurtLogger(socket: server);
  @override late PathfindingInterface pathfinder = RoverPathfinder(collection: this);
  @override late DetectorInterface detector = RoverDetector(collection: this);
  @override late VideoInterface video = RoverVideo(collection: this);
  @override late OrchestratorInterface orchestrator = RoverOrchestrator(collection: this);

  @override
  Future<void> onDisconnect() async {
    await super.onDisconnect();
    await orchestrator.abort();
  }
}
