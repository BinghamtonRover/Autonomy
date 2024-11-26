import "dart:io";

import "package:autonomy/interfaces.dart";
import "package:autonomy/rover.dart";
import "package:autonomy/simulator.dart";
import "package:autonomy/src/rover/imu.dart";
import "package:autonomy/src/simulator/network_detector.dart";
import "package:burt_network/burt_network.dart";

void main() async {
  ServerUtils.subsystemsDestination = SocketInfo(
    address: InternetAddress("192.168.1.40"),
    port: 8001,
  );
  final tank = RoverAutonomy();
  tank.detector = NetworkDetector(collection: tank);
  tank.gps = GpsSimulator(collection: tank);
  // tank.imu = ImuSimulator(collection: tank);
  tank.imu = RoverImu(collection: tank);
  tank.drive = RoverDrive(collection: tank, useGps: false);
  await tank.init();
  await tank.imu.waitForValue();

  await tank.server.waitForConnection();
}
