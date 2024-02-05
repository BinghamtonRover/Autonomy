import "dart:io";

import "package:autonomy/interfaces.dart";
import "package:burt_network/burt_network.dart";
import "package:meta/meta.dart";

final subsystemsDestination = SocketInfo(
  address: InternetAddress("192.168.1.20"),
  port: 8001,
);

abstract class ServerInterface extends RoverServer implements Service {
  final AutonomyInterface collection;
  ServerInterface({required this.collection, super.quiet}) : super(device: Device.AUTONOMY, port: 8003);

  void sendCommand(Message message) => sendMessage(message, destinationOverride: subsystemsDestination);

  @override
  void restart() => collection.restart();

  Future<void> waitForConnection() async {
    logger.info("Waiting for connection...");
    while (!isConnected) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return;
  }

  @override
  @mustCallSuper
  void onMessage(WrappedMessage wrapper) {
    if (wrapper.name == AutonomyCommand().messageName) {
      final command = AutonomyCommand.fromBuffer(wrapper.data);
      if (command.abort) {
        sendWrapper(wrapper);  // acknowledge receipt to the dashboard
        collection.orchestrator.abort();
        return;
      }
      collection.orchestrator.onCommand(command);
    }
  }
}
