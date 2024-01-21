import "package:burt_network/logging.dart";

import "src/simulator/drive.dart";
import "src/simulator/gps.dart";
import "src/simulator/imu.dart";
import "src/simulator/server.dart";

class AutonomySimulator {
  final server = SimulatorServer(port: 8001);
  final gps = GpsSimulator();
  final imu = ImuSimulator();
  final drive = DriveSimulator();

  Future<void> init() async {
    await server.init();
    await gps.init();
    await imu.init();
  }
}

final simulator = AutonomySimulator();
final logger = BurtLogger(socket: simulator.server);
