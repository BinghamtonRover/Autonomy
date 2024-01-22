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

  Future<void> simulate() async {  // Starts at (0, 0), North
    simulator.drive.turnRight();  // (0, 0), East
    await Future<void>.delayed(const Duration(seconds: 1));
    simulator.drive.goForward();  // (0, 1), East
    await Future<void>.delayed(const Duration(seconds: 1));
    simulator.drive.goForward();  // (0, 2), East
    await Future<void>.delayed(const Duration(seconds: 1));

    simulator.drive.turnLeft();  // (0, 2), North
    await Future<void>.delayed(const Duration(seconds: 1));
    simulator.drive.goForward();  // (1, 2), North
    await Future<void>.delayed(const Duration(seconds: 1));
    simulator.drive.goForward();  // (2, 2), North
    await Future<void>.delayed(const Duration(seconds: 1));
    
    simulator.drive.turnLeft();  // (2, 2), West
    await Future<void>.delayed(const Duration(seconds: 1));
    simulator.drive.goForward();  // (2, 1) West
    await Future<void>.delayed(const Duration(seconds: 1));

    simulator.drive.turnRight();
    await Future<void>.delayed(const Duration(seconds: 1));
    simulator.drive.goForward();
    await Future<void>.delayed(const Duration(seconds: 1));

    simulator.server.sendDone();
  }
}

final simulator = AutonomySimulator();
final logger = BurtLogger(socket: simulator.server);
