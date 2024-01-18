import "dart:io";
import "package:burt_network/burt_network.dart";

/// A server that listens and sends command to the subsystems program.
/// 
/// Unlike [ServerSocket]s, this class does not need to handle heartbeats, since both
/// programs are on the rover and connected via Ethernet. This server is used to drive
/// the rover and collect information such as [position].
class SubsystemsServer extends ProtoSocket {
	/// The current position and orientation of the rover.
	final position = RoverPosition();
	/// The state of the drive subsystem.
	final drive = DriveData();
  // RGB from RealSense (ROVER_FRONT)
  final rgbframe = VideoData();
  // Depth from RealSense (AUTONOMY_DEPTH)
  final depthframe = VideoData();
	/// Opens a connection to the subsystems program.
	SubsystemsServer({required super.port, required InternetAddress address}) : super(
		device: Device.AUTONOMY,
		heartbeatInterval: const Duration(seconds: 1),
		destination: SocketInfo(
			address: address, 
			port: 8001,
		),
	);

	@override
	Future<void> checkHeartbeats() async { }

	@override
	void onHeartbeat(Connect heartbeat, SocketInfo source) { }

	@override
	void updateSettings(UpdateSetting settings) { }

	@override
	void onMessage(WrappedMessage wrapper) { 
     logger.info("hi");
		if (wrapper.name == DriveData().messageName) {
			drive.mergeFromBuffer(wrapper.data);
		} else if (wrapper.name == RoverPosition().messageName) {
			position.mergeFromBuffer(wrapper.data);
      print("Got a position: $position");
		} else if (wrapper.name == VideoData().messageName){
      final message = VideoData.fromBuffer(wrapper.data);
      if (message.details.name == CameraName.ROVER_FRONT){
        rgbframe.mergeFromBuffer(wrapper.data);
      } else if (message.details.name == CameraName.AUTONOMY_DEPTH){
        depthframe.mergeFromBuffer(wrapper.data);
      }
    }
	}
}
