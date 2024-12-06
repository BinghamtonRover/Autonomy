import "package:autonomy/interfaces.dart";
import "package:burt_network/protobuf.dart";

const bool isRover = true;

enum DriveDirection {
  forward,
  left,
  right,
  forwardLeft,
  forwardRight,
  stop;

  bool get isTurn => this != forward && this != stop;
}

abstract class DriveInterface extends Service {
  AutonomyInterface collection;
  DriveInterface({required this.collection});

  Future<void> stop();

  Future<void> driveForward(AutonomyAStarState state);

  Future<void> turn(AutonomyAStarState state) => faceDirection(state.endOrientation);

  Future<void> faceDirection(CardinalDirection orientation);

  Future<void> resolveOrientation() => faceDirection(collection.imu.nearest);

  Future<void> driveState(AutonomyAStarState state) {
    if (state.direction == DriveDirection.stop) {
      return stop();
    }

    if (state.direction == DriveDirection.forward) {
      return driveForward(state);
    }

    return turn(state);
  }

  void setLedStrip(ProtoColor color, {bool blink = false}) {
    final command = DriveCommand(color: color, blink: blink ? BoolState.YES : BoolState.NO);
    collection.server.sendCommand(command);
  }

  Future<bool> spinForAruco() async => false;
  Future<void> approachAruco() async { }
}
