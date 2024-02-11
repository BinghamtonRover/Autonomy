import "package:burt_network/burt_network.dart";
import "package:autonomy/interfaces.dart";

final driveName = DriveCommand().messageName;

class SimulatorServer extends ServerInterface {
  SimulatorServer({
    required super.collection,
  }) : super(quiet: true);

  void sendDone() {
    final message = AutonomyData(state: AutonomyState.AT_DESTINATION, task: AutonomyTask.AUTONOMY_TASK_UNDEFINED);
    sendMessage(message);
  }
}
