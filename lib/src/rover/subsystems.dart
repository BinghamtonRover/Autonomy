import "dart:io";
import "package:burt_network/burt_network.dart";
import "package:autonomy/interfaces.dart";

/// A server that listens and sends command to the subsystems program.
/// 
/// Unlike [ServerSocket]s, this class does not need to handle heartbeats, since both
/// programs are on the rover and connected via Ethernet. This server is used to drive
/// the rover and collect information such as [position].
class SubsystemsServer extends RoverServer {  
  final AutonomyInterface collection;
  
	/// The current position and orientation of the rover.
	final position = RoverPosition();
	/// The state of the drive subsystem.
	final drive = DriveData();

  final InternetAddress address;

	/// Opens a connection to the subsystems program.
	SubsystemsServer({required super.port, required this.address, required this.collection}) : 
    super(device: Device.AUTONOMY);

  @override
  Future<void> init() async {
    destination = SocketInfo(
      address: address, 
      port: 8001,
    );
    await super.init();
  }

	@override
	void onMessage(WrappedMessage wrapper) { 
		if (wrapper.name == DriveData().messageName) {
			drive.mergeFromBuffer(wrapper.data);
		} else if (wrapper.name == RoverPosition().messageName) {
			position.mergeFromBuffer(wrapper.data);
		}
	}

  @override
  void restart() => collection.restart();
}
