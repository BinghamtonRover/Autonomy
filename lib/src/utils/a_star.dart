import "dart:math";

import "package:a_star/a_star.dart";

import "package:burt_network/protobuf.dart";
import "package:autonomy/interfaces.dart";

class AutonomyAStarState extends AStarState<AutonomyAStarState> {
  static double getCost(DriveDirection direction) {
    if (direction == DriveDirection.forward) {
      return 1;
    } else if (direction == DriveDirection.quarterLeft || direction == DriveDirection.quarterRight) {
      return sqrt2;
    } else {
      return 2 * sqrt2;
    }
  }

  final DriveDirection instruction;
  final GpsCoordinates position;
  final CardinalDirection orientation;
  final GpsCoordinates goal;
  final AutonomyInterface collection;

  AutonomyAStarState({
    required this.position,
    required this.goal,
    required this.collection,
    required this.instruction,
    required this.orientation,
    required super.depth,
  });

  factory AutonomyAStarState.start({
    required AutonomyInterface collection,
    required GpsCoordinates goal,
  }) => AutonomyAStarState(
    position: collection.gps.coordinates,
    goal: goal,
    collection: collection,
    instruction: DriveDirection.stop,
    orientation: collection.imu.orientation ?? collection.imu.nearest,
    depth: 0,
  );

  AutonomyAStarState copyWith({
    required DriveDirection direction,
    required CardinalDirection orientation,
    required GpsCoordinates position,
  }) => AutonomyAStarState(
    collection: collection,
    position: position,
    orientation: orientation,
    instruction: direction,
    goal: goal,
    depth: depth + getCost(direction),
  );

  @override
  String toString() => switch(instruction) {
    DriveDirection.forward => "Go forward to ${position.prettyPrint()}",
    DriveDirection.left => "Turn left to face $instruction",
    DriveDirection.right => "Turn right to face $instruction",
    DriveDirection.stop => "Start/Stop at ${position.prettyPrint()}",
    DriveDirection.quarterLeft => "Turn 45 degrees left to face $instruction",
    DriveDirection.quarterRight => "Turn 45 degrees right to face $instruction",
  };

  @override
  double heuristic() => position.distanceTo(goal);

  @override
  String hash() => "${position.prettyPrint()} ($orientation)";

  @override
  bool isGoal() => position.isNear(goal, min(GpsUtils.moveLengthMeters, GpsUtils.maxErrorMeters));

  /// Returns whether or not the rover will drive between or right next to an obstacle diagonally<br/>
  /// <br/>
  /// Case 1:<br/>
  /// 0 X<br/>
  /// X R<br/>
  /// Assuming the rover is facing 0 and trying to drive forward, will return false<br/>
  /// <br/>
  /// Case 2:<br/>
  /// 0 X<br/>
  /// X R<br/>
  /// Assuming the rover is facing north and trying to turn 45 degrees left, will return false<br/>
  /// <br/>
  /// Case 3:<br/>
  /// 0 X<br/>
  /// 0 R<br/>
  /// If the rover is facing left but trying to turn 45 degrees right, will return false<br/>
  /// <br/>
  /// Case 4:<br/>
  /// 0 X 0<br/>
  /// 0 R 0<br/>
  /// If the rover is facing northeast to 0 and trying to turn left, will return false
  bool willDriveThroughObstacle(AutonomyAStarState state) {
    final isTurn = state.instruction != DriveDirection.forward;
    final isQuarterTurn = state.instruction == DriveDirection.quarterLeft || state.instruction == DriveDirection.quarterRight;

    if (
      // Can't hit an obstacle while turning
      state.instruction != DriveDirection.forward

      // Forward drive across the perpendicular axis
      || (!isTurn && state.orientation.isPerpendicular)

      // Not encountering any sort of diagonal angle
      || (isTurn && isQuarterTurn && state.orientation.isPerpendicular)

      // No diagonal movement, won't drive between obstacles
      || (!isQuarterTurn && orientation.isPerpendicular)
    ) {
      return false;
    }

    final CardinalDirection orientation1;
    final CardinalDirection orientation2;

    // Case 1, trying to drive while facing a 45 degree angle
    if (!isTurn) {
      orientation1 = state.orientation.turnQuarterLeft();
      orientation2 = state.orientation.turnQuarterRight();
    } else if (isQuarterTurn) { // Case 2 and Case 3
      orientation1 = orientation;
      orientation2 = (state.instruction == DriveDirection.quarterLeft)
        ? orientation1.turnLeft()
        : orientation1.turnRight();
    } else { // Case 4
      orientation1 = (state.instruction == DriveDirection.left)
        ? orientation.turnQuarterLeft()
        : orientation.turnQuarterRight();
      orientation2 = (state.instruction == DriveDirection.left)
        ? state.orientation.turnQuarterLeft()
        : state.orientation.turnQuarterRight();
    }

    // Since the state being passed has a position of moving after the
    // turn, we have to check the position of where it started
    return collection.pathfinder.isObstacle(position.goForward(orientation1))
      || collection.pathfinder.isObstacle(position.goForward(orientation2));
  }

  bool isValidState(AutonomyAStarState state) =>
    !collection.pathfinder.isObstacle(state.position)
    && !willDriveThroughObstacle(state);

  Iterable<AutonomyAStarState> _allNeighbors() => [
    copyWith(
      direction: DriveDirection.forward,
      orientation: orientation,
      position: position.goForward(orientation),
    ),
    copyWith(
      direction: DriveDirection.left,
      orientation: orientation.turnLeft(),
      position: position,
    ),
    copyWith(
      direction: DriveDirection.right,
      orientation: orientation.turnRight(),
      position: position,
    ),
    copyWith(
      direction: DriveDirection.quarterLeft,
      orientation: orientation.turnQuarterLeft(),
      position: position,
    ),
    copyWith(
      direction: DriveDirection.quarterRight,
      orientation: orientation.turnQuarterRight(),
      position: position,
    ),
    copyWith(
      direction: DriveDirection.stop,
      orientation: orientation,
      position: position,
    ),
  ];

  @override
  Iterable<AutonomyAStarState> expand() => _allNeighbors().where(isValidState);
}
