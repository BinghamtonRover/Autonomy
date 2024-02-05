import "package:burt_network/burt_network.dart";
import "package:autonomy/interfaces.dart";

/// A server to handle incoming [AutonomyCommand]s and send [AutonomyData]s.
class AutonomyServer extends ServerInterface {
  /// Creates an autonomy server at the given port.
  AutonomyServer({required super.collection});

  @override
  void onCommand(AutonomyCommand command) {
    // TODO: Implement this
  }

  @override
  void onAbort() {
    // TODO: Implement this
  }

  @override
  void onMessage(WrappedMessage wrapper) {
    if (wrapper.name == RoverPosition().messageName) {
      final message = RoverPosition.fromBuffer(wrapper.data);
      if (message.hasGps()) collection.gps.update(message.gps);
      if (message.hasOrientation()) collection.imu.update(message.orientation);
    }
    super.onMessage(wrapper);
  }

  @override
  Future<void> init() async {
    await super.init();
    collection.logger.info("Initialized server");
  }
}
