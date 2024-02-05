import "package:burt_network/burt_network.dart";
import "package:autonomy/interfaces.dart";

/// A helper class to send drive commands to the rover with a simpler API. 
class RoverDrive extends DriveInterface {
  // TODO: Calibrate these
  static const maxThrottle = 0.2;
  static const turnThrottle = 0.1;
  static const oneMeterDelay = Duration(seconds: 1);
  static const turnDelay = Duration(seconds: 1);
  RoverDrive({required super.collection});

	/// Initializes the rover's drive subsystems.
	@override 
  Future<void> init() async { }

	/// Stops the rover from driving.
	@override 
  Future<void> dispose() => stop();

	/// Sets the max speed of the rover. 
	/// 
	/// [setSpeeds] takes the speeds of each side of wheels. These numbers are percentages of the
	/// max speed allowed by the rover, which we call the throttle. This function adjusts the 
	/// throttle, as a percentage of the rover's top speed. 
	void setThrottle(double throttle) {
		collection.logger.trace("Setting throttle to $throttle");
		collection.server.sendCommand(DriveCommand(throttle: throttle, setThrottle: true));
	}

	/// Sets the speeds of the left and right wheels, using differential steering. 
	/// 
	/// These values are percentages of the max speed allowed by the rover. See [setThrottle].
	void setSpeeds({required double left, required double right}) {
		collection.logger.trace("Setting speeds to $left and $right");
		collection.server.sendCommand(DriveCommand(left: left, setLeft: true));
		collection.server.sendCommand(DriveCommand(right: right, setRight: true));
	}

	/// Sets the angle of the front camera.
	void setCameraAngle({required double swivel, required double tilt}) {
		collection.logger.trace("Setting camera angles to $swivel (swivel) and $tilt (tilt)");
		final command = DriveCommand(frontSwivel: swivel, frontTilt: tilt);
		collection.server.sendCommand(command);
	}

  @override 
  Future<void> stop() async {
    setThrottle(0);
    setSpeeds(left: 0, right: 0);
  }

  @override 
  Future<void> goForward() async {
    setThrottle(maxThrottle);
    setSpeeds(left: 1, right: 1);
    await Future<void>.delayed(oneMeterDelay);
    await stop();
  }

  @override
  Future<void> turnLeft() async {
    setThrottle(turnThrottle);
    setSpeeds(left: -1, right: 1);
    await Future<void>.delayed(turnDelay);
    await stop();
  }

  @override
  Future<void> turnRight() async {
    setThrottle(turnThrottle);
    setSpeeds(left: 1, right: -1);
    await Future<void>.delayed(turnDelay);
    await stop();
  }
}
