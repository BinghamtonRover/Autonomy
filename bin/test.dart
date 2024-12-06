// import "package:autonomy/autonomy.dart";
// import "package:burt_network/logging.dart";
// import "package:autonomy/src/gps/rover_gps.dart";
// import "package:autonomy/src/imu/rover_imu.dart";

// void main() async {
//   Logger.level = LogLevel.all;
//   final rover = RoverAutonomy();
//   rover.gps = RoverGps(collection: rover);
//   rover.imu = RoverImu(collection: rover);
//   rover.drive = RoverDrive(collection: rover, useGps: false, useImu: true);

//   await rover.init();
//   print("Waiting for readings");
// //  await rover.waitForReadings();
// //  await rover.waitForConnection();

//   rover.logger.info("Starting");
//   await rover.drive.turnLeft();
//   await rover.drive.turnRight();

//   rover.logger.info("Done");
//   await rover.dispose();
// }
