export "src/rover/drive.dart";
export "src/rover/server.dart";

import "package:autonomy/interfaces.dart";
import "package:autonomy/simulator.dart";

import "package:autonomy/src/simulator/pathfinding.dart";

import "src/rover/server.dart";
import "src/rover/drive.dart";

import "package:burt_network/logging.dart";

/// A collection of all the different services used by the autonomy program.
class RoverAutonomy extends AutonomyInterface {
	/// A server to communicate with the dashboard and receive data from the subsystems.
	@override late final AutonomyServer server = AutonomyServer(collection: this);
	/// A helper class to handle driving the rover.
	@override late final RoverDrive drive = RoverDrive(collection: this);
  @override late final gps = GpsSimulator(collection: this);
  @override late final imu = ImuSimulator(collection: this);
  @override late final logger = BurtLogger(socket: server);
  @override late final pathfinder = PathfindingSimulator(collection: this);
}
