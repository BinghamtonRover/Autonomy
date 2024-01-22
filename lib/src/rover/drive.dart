import "package:burt_network/burt_network.dart";
import "package:autonomy/interfaces.dart";

/// A helper class to send drive commands to the rover with a simpler API. 
class RoverDrive extends DriveInterface {
  RoverDrive({required super.collection});

	/// Initializes the rover's drive subsystems.
	void init() => setThrottle(0.3);
	/// Stops the rover from driving.
	void dispose() => setThrottle(0);

	/// Sets the max speed of the rover. 
	/// 
	/// [setSpeeds] takes the speeds of each side of wheels. These numbers are percentages of the
	/// max speed allowed by the rover, which we call the throttle. This function adjusts the 
	/// throttle, as a percentage of the rover's top speed. 
	void setThrottle(double throttle) {
		collection.logger.debug("Setting throttle to $throttle");
		final command = DriveCommand(throttle: throttle, setThrottle: true);
		collection.server.sendMessage(command);
	}

	/// Sets the speeds of the left and right wheels, using differential steering. 
	/// 
	/// These values are percentages of the max speed allowed by the rover. See [setThrottle].
	void setSpeeds({required double left, required double right}) {
		collection.logger.debug("Setting speeds to $left and $right");
		final command = DriveCommand(left: left, right: right, setLeft: true, setRight: true);
		collection.server.sendMessage(command);
	}

	/// Sets the angle of the front camera.
	void setCameraAngle({required double swivel, required double tilt}) {
		collection.logger.debug("Setting camera angles to $swivel (swivel) and $tilt (tilt)");
		final command = DriveCommand(frontSwivel: swivel, frontTilt: tilt);
		collection.server.sendMessage(command);
	}

  @override void goForward() { }
  @override void turnLeft() { }
  @override void turnRight() { }
  @override void stop() { }
}
