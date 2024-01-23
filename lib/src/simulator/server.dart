import "package:burt_network/burt_network.dart";
import "package:autonomy/interfaces.dart";

final driveName = DriveCommand().messageName;

class SimulatorServer extends ServerInterface {
  SimulatorServer({
    required super.collection,
  }) : super();
  
  @override
  void onMessage(WrappedMessage wrapper) {
    if (wrapper.name == driveName) {
      final command = DriveCommand.fromBuffer(wrapper.data);
      collection.drive.goDirection(command.direction);
    }
  }

  @override
  Future<void> onConnect(SocketInfo source) async {
    super.onConnect(source);
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
    sendMessage(message);
  }

  @override
  void restart() { }

  void sendDone() {
    final message = AutonomyData(state: AutonomyState.AT_DESTINATION, task: AutonomyTask.AUTONOMY_TASK_UNDEFINED);
    sendMessage(message);
  }
}
