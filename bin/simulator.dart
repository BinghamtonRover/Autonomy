import "package:burt_network/logging.dart";
import "package:autonomy/simulator.dart";

void main() async {  // (lat, long), direction
  Logger.level = LogLevel.info;
  final simulator = AutonomySimulator();
  await simulator.init();  // (0, 0), North
}
