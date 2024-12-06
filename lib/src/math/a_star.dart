import "dart:math";

import "package:a_star/a_star.dart";

import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

class AutonomyAStarState extends AStarState<AutonomyAStarState> {
  final DriveDirection direction;
  final GpsCoordinates endPosition;
  final DriveOrientation endOrientation;
  final GpsCoordinates pathGoal;
  final AutonomyInterface collection;

  GpsCoordinates get startPosition => switch(direction) {
    DriveDirection.forward => endPosition.goBackward(endOrientation),
    DriveDirection.left => endPosition,
    DriveDirection.right => endPosition,
    DriveDirection.forwardLeft => endPosition,
    DriveDirection.forwardRight => endPosition,
    DriveDirection.stop => endPosition,
  };

  DriveOrientation get startOrientation => switch (direction) {
      DriveDirection.forward => endOrientation,
      DriveDirection.left => endOrientation.turnRight(),
      DriveDirection.right => endOrientation.turnLeft(),
      DriveDirection.forwardLeft => endOrientation.turnQuarterRight(),
      DriveDirection.forwardRight => endOrientation.turnQuarterLeft(),
      DriveDirection.stop => endOrientation,
    };

  AutonomyAStarState({
    required this.endPosition,
    required this.pathGoal,
    required this.collection,
    required this.direction,
    required this.endOrientation,
    required super.depth,
  });

  factory AutonomyAStarState.start({
    required AutonomyInterface collection,
    required GpsCoordinates goal,
  }) => AutonomyAStarState(
    endPosition: collection.gps.coordinates,
    pathGoal: goal,
    collection: collection,
    direction: DriveDirection.stop,
    endOrientation: collection.imu.orientation ?? collection.imu.nearest,
    depth: 0,
  );

  @override
  String toString() => switch(direction) {
    DriveDirection.forward => "Go forward to ${endPosition.prettyPrint()}",
    DriveDirection.left => "Turn left to face $direction",
    DriveDirection.right => "Turn right to face $direction",
    DriveDirection.stop => "Start/Stop at ${endPosition.prettyPrint()}",
    DriveDirection.forwardLeft => "Turn 45 degrees left to face $direction",
    DriveDirection.forwardRight => "Turn 45 degrees right to face $direction",
  };

  @override
  double heuristic() => endPosition.distanceTo(pathGoal);

  @override
  String hash() => "${endPosition.prettyPrint()} ($endOrientation)";

  @override
  bool isGoal() => endPosition.isNear(pathGoal, min(GpsUtils.moveLengthMeters, GpsUtils.maxErrorMeters));

  AutonomyAStarState copyWith({required DriveDirection direction, required DriveOrientation orientation, required GpsCoordinates position}) => AutonomyAStarState(
    collection: collection,
    endPosition: position,
    endOrientation: orientation,
    direction: direction,
    pathGoal: pathGoal,
    depth: (direction == DriveDirection.forward)
        ? depth + 1
        : (direction == DriveDirection.forwardLeft || direction == DriveDirection.forwardRight)
            ? depth + sqrt2
            : depth + 2 * sqrt2,
  );

  AutonomyAStarState moveDirection(DriveDirection direction) => switch(direction) {
      DriveDirection.forward => copyWith(
          direction: direction,
          orientation: endOrientation,
          position: endPosition.goForward(endOrientation),
        ),
      DriveDirection.left => copyWith(
          direction: direction,
          orientation: endOrientation.turnLeft(),
          position: endPosition,
        ),
      DriveDirection.right => copyWith(
          direction: direction,
          orientation: endOrientation.turnRight(),
          position: endPosition,
        ),
      DriveDirection.forwardLeft => copyWith(
          direction: direction,
          orientation: endOrientation.turnQuarterLeft(),
          position: endPosition,
        ),
      DriveDirection.forwardRight => copyWith(
          direction: direction,
          orientation: endOrientation.turnQuarterRight(),
          position: endPosition,
        ),
      DriveDirection.stop => copyWith(
          direction: direction,
          orientation: endOrientation,
          position: endPosition,
        ),
    };

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
  bool drivingThroughObstacle(AutonomyAStarState state) {
    final isTurn = state.direction != DriveDirection.forward;
    final isQuarterTurn = state.direction == DriveDirection.forwardLeft || state.direction == DriveDirection.forwardRight;

    if (state.direction != DriveDirection.forward) {
      return false;
    }

    // Forward drive across the perpendicular axis
    if (!isTurn && state.endOrientation.isPerpendicular) {
      return false;
    }

    // Not encountering any sort of diagonal angle
    if (isTurn && isQuarterTurn && state.endOrientation.isPerpendicular) {
      return false;
    }

    // No diagonal movement, won't drive between obstacles
    if (!isQuarterTurn && endOrientation.isPerpendicular) {
      return false;
    }

    DriveOrientation orientation1;
    DriveOrientation orientation2;

    // Case 1, trying to drive while facing a 45 degree angle
    if (!isTurn) {
      orientation1 = state.endOrientation.turnQuarterLeft();
      orientation2 = state.endOrientation.turnQuarterRight();
    } else if (isQuarterTurn) { // Case 2 and Case 3
      orientation1 = endOrientation;
      orientation2 = (state.direction == DriveDirection.forwardLeft)
          ? orientation1.turnLeft()
          : orientation1.turnRight();
    } else { // Case 4
      orientation1 = (state.direction == DriveDirection.left)
          ? endOrientation.turnQuarterLeft()
          : endOrientation.turnQuarterRight();
      orientation2 = (state.direction == DriveDirection.left)
          ? state.endOrientation.turnQuarterLeft()
          : state.endOrientation.turnQuarterRight();
    }

    // Since the state being passed has a position of moving after the
    // turn, we have to check the position of where it started
    return collection.pathfinder.isObstacle(
          endPosition.goForward(orientation1),
        ) ||
        collection.pathfinder.isObstacle(
          endPosition.goForward(orientation2),
        );
  }

  bool isValidState(AutonomyAStarState state) =>
    !collection.pathfinder.isObstacle(state.endPosition)
    && !drivingThroughObstacle(state);

  @override
  Iterable<AutonomyAStarState> expand() => DriveDirection.values
    .map(moveDirection)
    .where(isValidState);
}
