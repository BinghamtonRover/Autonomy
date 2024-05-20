import "package:autonomy/autonomy.dart";
import "package:burt_network/logging.dart";

void main() async {
  Logger.level = LogLevel.all;
  final rover = RoverAutonomy();
  await rover.init();
  rover.logger.info("Waiting for GPS and IMU reading...");
  await rover.waitForValue();
  rover.logger.info("Waiting for Dashboard...");
  await rover.server.waitForConnection();
  rover.logger.info("Waiting for commands");
}
