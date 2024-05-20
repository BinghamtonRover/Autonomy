import "package:autonomy/autonomy.dart";
import "package:burt_network/logging.dart";

void main() async {
  Logger.level = LogLevel.all;
  final rover = RoverAutonomy();
  rover.gps = GpsSimulator(collection: rover);
  rover.imu = ImuSimulator(collection: rover);
  rover.drive = RoverDrive(collection: rover, useGps: false, useImu: true);
  
  await rover.init();
  await rover.waitForValue();
  await rover.server.waitForConnection();

  // rover.logger.info("Done");
  // await rover.dispose();
}
