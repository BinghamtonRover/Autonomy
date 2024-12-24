import "package:autonomy/interfaces.dart";

mixin RoverDriveCommands on DriveInterface {
  /// Sets the max speed of the rover.
  ///
  /// [_setSpeeds] takes the speeds of each side of wheels. These numbers are percentages of the
  /// max speed allowed by the rover, which we call the throttle. This function adjusts the
  /// throttle, as a percentage of the rover's top speed.
  void setThrottle(double throttle) {
    collection.logger.trace("Setting throttle to $throttle");
    sendCommand(DriveCommand(throttle: throttle, setThrottle: true));
  }

  /// Sets the speeds of the left and right wheels, using differential steering.
  ///
  /// These values are percentages of the max speed allowed by the rover. See [setThrottle].
  void _setSpeeds({required double left, required double right}) {
    right *= -1;
    collection.logger.trace("Setting speeds to $left and $right");
    sendCommand(DriveCommand(left: left, setLeft: true));
    sendCommand(DriveCommand(right: right, setRight: true));
  }

  void stopMotors() {
    setThrottle(0);
    _setSpeeds(left: 0, right: 0);
  }

  void spinLeft() => _setSpeeds(left: -1, right: 1);
  void spinRight() => _setSpeeds(left: 1, right: -1);
  void moveForward() => _setSpeeds(left: 1, right: 1);

  /// Sets the angle of the front camera.
  void setCameraAngle({required double swivel, required double tilt}) {
    collection.logger.trace("Setting camera angles to $swivel (swivel) and $tilt (tilt)");
    final command = DriveCommand(frontSwivel: swivel, frontTilt: tilt);
    sendCommand(command);
  }
}
