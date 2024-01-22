export "src/rover/drive.dart";
export "src/rover/server.dart";
export "src/rover/subsystems.dart";

import "dart:io";

import "package:autonomy/interfaces.dart";
import "package:autonomy/simulator.dart";

import "src/rover/server.dart";
import "src/rover/drive.dart";
import "src/rover/subsystems.dart";

import "package:burt_network/logging.dart";

/// The IP address of the subsystems server.
final subsystemsAddress = InternetAddress("192.168.1.20");

/// A collection of all the different services used by the autonomy program.
class RoverAutonomy extends AutonomyInterface {
	/// A server to communicate with the dashboard.
	@override final AutonomyServer server = AutonomyServer(port: 8003);
	/// A server to communicate with the subsystems.
	late final SubsystemsServer subsystems;
	/// A helper class to handle driving the rover.
	@override late final RoverDrive drive = RoverDrive(collection: this);
  @override late final gps = GpsSimulator(collection: this);
  @override late final imu = ImuSimulator(collection: this);
  @override late final logger = BurtLogger(socket: server);

  bool tankMode = false;

	/// Initializes the rover, overriding the [subsystems] server if [tankMode] is true.
  @override
	Future<void> init() async {
		subsystems = SubsystemsServer(
			port: 8004, 
      collection: this,
			address: tankMode ? InternetAddress.loopbackIPv4 : subsystemsAddress,
		);
		await subsystems.init();
		await server.init();
		drive.init();
	}

  @override
  Future<void> dispose() async {
    await server.dispose();
    await subsystems.dispose();
    drive.dispose();
  }

  @override
  Future<void> restart() async {
    await dispose();
    await init();
  }
}
