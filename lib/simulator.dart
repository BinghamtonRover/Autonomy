export "src/detector/sim_detector.dart";
export "src/drive/sim_drive.dart";
export "src/gps/sim_gps.dart";
export "src/imu/sim_imu.dart";
export "src/video/sim_video.dart";

import "package:autonomy/interfaces.dart";
import "package:autonomy/src/orchestrator/sim_orchestrator.dart";
import "package:burt_network/burt_network.dart";

import "src/detector/sim_detector.dart";
import "src/drive/sim_drive.dart";
import "src/gps/sim_gps.dart";
import "src/imu/sim_imu.dart";
import "src/pathfinding/sim_pathfinding.dart";
import "src/video/sim_video.dart";

class AutonomySimulator extends AutonomyInterface {
  @override late final logger = BurtLogger(socket: server);
  @override late final server = RoverSocket(port: 8003, device: Device.AUTONOMY, collection: this);
  @override late GpsInterface gps = GpsSimulator(collection: this);
  @override late ImuInterface imu = ImuSimulator(collection: this);
  @override late DriveInterface drive = DriveSimulator(collection: this);
  @override late PathfindingInterface pathfinder = PathfindingSimulator(collection: this);
  @override late DetectorInterface detector = DetectorSimulator(collection: this, obstacles: []);
  @override late VideoInterface video = VideoSimulator(collection: this);
  @override late OrchestratorInterface orchestrator = OrchestratorSimulator(collection: this);

  bool isInitialized = false;

  @override
  Future<bool> init() { isInitialized = true; return super.init(); }

  @override
  Future<void> dispose() { isInitialized = false; return super.dispose(); }
}
