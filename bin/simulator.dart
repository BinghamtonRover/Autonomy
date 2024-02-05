import "package:burt_network/logging.dart";
import "package:burt_network/generated.dart";
import "package:autonomy/simulator.dart";

void main() async {
  Logger.level = LogLevel.info;
  final simulator = AutonomySimulator();
  await simulator.init();
  await simulator.server.waitForConnection();
  final message = AutonomyData(
    destination: GpsCoordinates(latitude: 3, longitude: 1),
    state: AutonomyState.DRIVING,
    task: AutonomyTask.GPS_ONLY,
    obstacles: [GpsCoordinates(latitude: 1, longitude: 1)],
    path: [
      GpsCoordinates(latitude: 0, longitude: 1),
      GpsCoordinates(latitude: 0, longitude: 2),
      GpsCoordinates(latitude: 1, longitude: 2),
      GpsCoordinates(latitude: 2, longitude: 2),
      GpsCoordinates(latitude: 2, longitude: 1),
      GpsCoordinates(latitude: 3, longitude: 1),
    ],
  );
  simulator.server.sendMessage(message);
}
