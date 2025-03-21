import "package:autonomy/interfaces.dart";
import "package:behavior_tree/behavior_tree.dart";

import "drive_config.dart";

/// An enum for the drive direction or "instruction" for how the rover should drive
enum DriveDirection {
  /// Move forward
  forward,
  /// Turn 90 degrees left
  left,
  /// Turn 90 degrees right
  right,
  /// Turn 45 degrees left
  quarterLeft,
  /// Turn 45 degrees right
  quarterRight,
  /// Stop moving
  stop;

  /// Whether or not this is a turn
  bool get isTurn => this != forward && this != stop;

  /// Whether or not this is a quarter turn of 45 degrees
  bool get isQuarterTurn => this == quarterLeft || this == quarterRight;
}

/// An abstract class for driving.
/// 
/// This allows for easy stubbing to simulate drive if certain sensors are not used.
abstract class DriveInterface extends Service {
  /// The autonomy collection of the rover's sensors, pathfinders, loggers, and UDP sockets
  AutonomyInterface collection;

  /// The drive configuration for the rover it is running on
  DriveConfig config;

  /// Constructor for Drive Interface
  DriveInterface({required this.collection, this.config = roverConfig});

  BaseNode driveStateNode(AutonomyAStarState state) {
    if (state.instruction == DriveDirection.stop) {
      return Task(() {
        stop();
        return NodeStatus.success;
      });
    } else if (state.instruction == DriveDirection.forward) {
      return driveForwardNode(state.position);
    } else {
      return turnStateNode(state);
    }
  }

  BaseNode resolveOrientationNode() =>
      faceDirectionNode(collection.imu.nearest);

  BaseNode driveForwardNode(GpsCoordinates coordinates);

  BaseNode faceDirectionNode(CardinalDirection direction) =>
      faceOrientationNode(direction.orientation);

  BaseNode faceOrientationNode(Orientation orientation);

  BaseNode turnStateNode(AutonomyAStarState state) =>
      faceOrientationNode(state.orientation.orientation);

  BaseNode spinForArucoNode(int arucoId, {CameraName? desiredCamera}) =>
      Condition(() => false);

  /// Stop the rover
  Future<bool> stop();

  /// Drive forward to [position], returns whether or not it successfully drove to the position
  Future<bool> driveForward(GpsCoordinates position);

  /// Turn to face [orientation], returns whether or not it was able to turn
  Future<bool> faceOrientation(Orientation orientation);

  /// Turn to face the orientation of [direction], returns whether or not it was able to turn
  Future<bool> faceDirection(CardinalDirection direction) => faceOrientation(direction.orientation);

  /// Utility method to send a command to subsystems
  void sendCommand(Message message) => collection.server.sendMessage(message, destination: config.subsystems);

  /// Spins the rover to the nearest IMU rotation
  /// 
  /// This exists so the rover can generate a path based on a known
  /// orientation that aligns to the possible orientations defined by [CardinalDirection]
  Future<bool> resolveOrientation() => faceDirection(collection.imu.nearest);

  /// Turns to face the state's [AutonomyAStarState.orientation].
  ///
  /// Exists so that the TimedDrive can implement this in terms of [AutonomyAStarState.instruction].
  /// 
  /// Returns whether or not the turn was successful
  Future<bool> turnState(AutonomyAStarState state) => faceDirection(state.orientation);

  /// Drives the rover based on the instruction and desired positions in [state]
  /// 
  /// This determines based on the [state] whether it should move forward, turn, or stop
  /// 
  /// Returns whether or not the drive was successful
  Future<bool> driveState(AutonomyAStarState state) {
    if (state.instruction == DriveDirection.stop) {
      return stop();
    } else if (state.instruction == DriveDirection.forward) {
      return driveForward(state.position);
    } else {
      return turnState(state);
    }
  }

  /// Utility method to send a command to change the color of the LED strip
  /// 
  /// This is used to signal the state of the autonomous driving outside of the rover
  void setLedStrip(ProtoColor color, {bool blink = false}) {
    final command = DriveCommand(color: color, blink: blink ? BoolState.YES : BoolState.NO);
    sendCommand(command);
  }

  /// Spin to face an Aruco tag, returns whether or not it was able to face the tag
  Future<bool> spinForAruco(int arucoId, {CameraName? desiredCamera}) async => false;

  /// Drive forward to approach an Aruco tag
  Future<void> approachAruco() async { }
}
