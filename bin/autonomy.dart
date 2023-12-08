import "package:autonomy/autonomy.dart";
import "package:burt_network/logging.dart";

Future<void> testCommands(AutonomyCollection collection) async {
  collection.drive.setThrottle(0.3);
  logger.info("Throttle set to 0.3");
  collection.drive.setSpeeds(left: 0.5, right: 0.5); 
  logger.info("Speed set to 0.5 ");
  await Future<void>.delayed(const Duration(seconds: 1));

  collection.drive.setThrottle(0.2);
  logger.info("Throttle set to 0.3");

  await Future<void>.delayed(const Duration(seconds: 1));
  collection.drive.setSpeeds(left: 0.6, right: 0.6); 
  logger.info("Speed set to 0.5 ");

  await Future<void>.delayed(const Duration(seconds: 1));
  collection.drive.setThrottle(0);
  logger.info("Throttle set to 0 - Rover should stop");

  await Future<void>.delayed(const Duration(seconds: 1));
  collection.drive.setSpeeds(left: 0.6, right: 0.6); 
  logger.info("Speed set to 0.6 - Throttle should be 0(rover should stop)");
}

void main(List<String> arguments) async {
  final tankMode = arguments.contains("--tank");
  if (tankMode) logger.info("Running in tank mode");
  await collection.init(tankMode: arguments.contains("--tank"));
  await testCommands(collection);
}
