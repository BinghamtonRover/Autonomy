import "package:burt_network/logging.dart";

import "package:autonomy/interfaces.dart";

abstract class AutonomyInterface extends Service {
  BurtLogger get logger;
  GpsInterface get gps;
  ImuInterface get imu;
  DriveInterface get drive;
  ServerInterface get server;
  PathfindingInterface get pathfinder;
  DetectorInterface get detector;
  RealSenseInterface get realsense;
  OrchestratorInterface get orchestrator;
  
  @override
  Future<void> init() async {
    await gps.init();
    await imu.init();
    await drive.init();
    await server.init();
    await pathfinder.init();
    await detector.init();
    await realsense.init();
    await orchestrator.init();
  }
  
  @override
  Future<void> dispose() async {
    await server.dispose();
    await gps.dispose();
    await imu.dispose();
    await drive.dispose();
    await pathfinder.dispose();
    await detector.dispose();
    await realsense.dispose();
    await orchestrator.dispose();
  }
  
  Future<void> restart() async {
    await init();
    await dispose();
  }
}
