import "package:autonomy/interfaces.dart";

import "drive_config.dart";

enum DriveDirection {
  forward,
  left,
  right,
  quarterLeft,
  quarterRight,
  stop;

  bool get isTurn => this != forward && this != stop;
}

abstract class DriveInterface extends Service {
  AutonomyInterface collection;
  DriveInterface({required this.collection});

  DriveConfig get config => roverConfig;

  Future<void> stop();

  Future<void> driveForward(GpsCoordinates position);

  Future<void> faceDirection(CardinalDirection orientation);

  void sendCommand(Message message) => collection.server
    .sendMessage(message, destination: config.subsystems);

  Future<void> resolveOrientation() => faceDirection(collection.imu.nearest);

  /// Turns to face the state's [AutonomyAStarState.orientation].
  ///
  /// Exists so that the TimedDrive can implement this in terms of [AutonomyAStarState.instruction].
  Future<void> turnState(AutonomyAStarState state) => faceDirection(state.orientation);

  Future<void> driveState(AutonomyAStarState state) {
    if (state.instruction == DriveDirection.stop) {
      return stop();
    } else if (state.instruction == DriveDirection.forward) {
      return driveForward(state.position);
    } else {
      return turnState(state);
    }
  }

  void setLedStrip(ProtoColor color, {bool blink = false}) {
    final command = DriveCommand(color: color, blink: blink ? BoolState.YES : BoolState.NO);
    sendCommand(command);
  }

  Future<bool> spinForAruco() async => false;
  Future<void> approachAruco() async { }
}
