export "src/simulator/drive.dart";
export "src/simulator/gps.dart";
export "src/simulator/imu.dart";
export "src/simulator/server.dart";

import "package:autonomy/interfaces.dart";
import "package:burt_network/logging.dart";

import "src/simulator/drive.dart";
import "src/simulator/gps.dart";
import "src/simulator/imu.dart";
import "src/simulator/server.dart";

class AutonomySimulator extends AutonomyInterface {
  @override
  late final SimulatorServer server = SimulatorServer(port: 8001, collection: this);

  @override
  late final GpsSimulator gps = GpsSimulator(collection: this);

  @override
  late final ImuSimulator imu = ImuSimulator(collection: this);

  @override
  late final DriveSimulator drive = DriveSimulator(collection: this);

  @override
  late final BurtLogger logger = BurtLogger(socket: server);

  @override
  Future<void> init() async {
    await server.init();
    gps.init();
    imu.init();
  }

  @override
  Future<void> dispose() async {
    await server.dispose();
    gps.dispose();
    imu.dispose();
  }

  Future<void> testDrive({bool delay = true}) async {  // Starts at (0, 0), North
    drive.turnRight();  // (0, 0), East
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));
    drive.goForward();  // (0, 1), East
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));
    drive.goForward();  // (0, 2), East
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));

    drive.turnLeft();  // (0, 2), North
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));
    drive.goForward();  // (1, 2), North
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));
    drive.goForward();  // (2, 2), North
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));
    
    drive.turnLeft();  // (2, 2), West
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));
    drive.goForward();  // (2, 1) West
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));

    drive.turnRight();  // (2, 1), North
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));
    drive.goForward();  // (3, 1), North
    if (delay) await Future<void>.delayed(const Duration(seconds: 1));

    server.sendDone();
  }
}
