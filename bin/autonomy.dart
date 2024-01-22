import "package:autonomy/rover.dart";

void main(List<String> arguments) async {
  final rover = RoverAutonomy();
  final tankMode = arguments.contains("--tank");
  if (tankMode) rover.logger.info("Running in tank mode");
  rover.tankMode = arguments.contains("--tank");
  await rover.init();
}
