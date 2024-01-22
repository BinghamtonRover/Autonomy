import "package:burt_network/burt_network.dart";
import "package:burt_network/logging.dart";

import "gps.dart";
import "imu.dart";
import "drive.dart";

abstract class AutonomyInterface {
  BurtLogger get logger;
  GpsInterface get gps;
  ImuInterface get imu;
  DriveInterface get drive;
  RoverServer get server;

  Future<void> init();
  Future<void> dispose();
  
  Future<void> restart() async {
    await init();
    await dispose();
  }
}
