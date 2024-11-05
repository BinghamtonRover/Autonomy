import "dart:math";

import "package:a_star/a_star.dart";

import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

class AutonomyAStarState extends AStarState<AutonomyAStarState> {
  final DriveDirection direction;
  final DriveOrientation orientation;
  final GpsCoordinates position;
  final GpsCoordinates goal;
  final AutonomyInterface collection;

  AutonomyAStarState({
    required this.position, 
    required this.goal, 
    required this.collection,
    required this.direction,
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
    direction: DriveDirection.stop, 
    orientation: collection.imu.orientation!, 
    depth: 0,
  );

  @override
  String toString() => switch(direction) {
    DriveDirection.forward => "Go forward to ${position.prettyPrint()}",
    DriveDirection.left => "Turn left to face $direction",
    DriveDirection.right => "Turn right to face $direction",
    DriveDirection.stop => "Start/Stop at ${position.prettyPrint()}",
    DriveDirection.forwardLeft => "Turn 45 degrees left to face $direction",
    DriveDirection.forwardRight => "Turn 45 degrees right to face $direction",
  };

  @override
  double heuristic() => position.distanceTo(goal);

  @override
  String hash() => "${position.prettyPrint()} ($orientation)";

  @override
  bool isGoal() => position.isNear(goal);

  AutonomyAStarState copyWith({required DriveDirection direction, required DriveOrientation orientation, required GpsCoordinates position}) => AutonomyAStarState(
    collection: collection,
    position: position,
    orientation: orientation, 
    direction: direction,
    goal: goal, 
    depth: (direction == DriveDirection.forward)
        ? depth + 1
        : (direction == DriveDirection.forwardLeft || direction == DriveDirection.forwardRight)
            ? depth + sqrt2
            : depth + 2,
  );

  bool drivingThroughObstacle(AutonomyAStarState state) {
    final isTurn = state.direction != DriveDirection.forward;
    final isQuarterTurn = state.direction == DriveDirection.forwardLeft || state.direction == DriveDirection.forwardRight;

    // Forward drive across the perpendicular axis
    if (!isTurn && state.orientation.angle.abs() % 90 == 0) {
      return false;
    }

    // Not encountering any sort of diagonal angle
    if (isTurn && isQuarterTurn && state.orientation.angle.abs() % 90 == 0) {
      return false;
    }

    // No diagonal movement, won't drive between obstacles
    if (!isQuarterTurn && orientation.angle.abs() % 90 == 0) {
      return false;
    }

    DriveOrientation orientation1;
    DriveOrientation orientation2;

    if (!isTurn) {
      orientation1 = state.orientation.turnQuarterLeft();
      orientation2 = state.orientation.turnQuarterRight();
    } else if (isQuarterTurn) {
      orientation1 = orientation;
      orientation2 = (state.direction == DriveDirection.forwardLeft)
          ? orientation1.turnLeft()
          : orientation1.turnRight();
    } else {
      orientation1 = (state.direction == DriveDirection.left)
          ? orientation.turnQuarterLeft()
          : orientation.turnQuarterRight();
      orientation2 = (state.direction == DriveDirection.left)
          ? state.orientation.turnQuarterLeft()
          : state.orientation.turnQuarterRight();
    }

    // Since the state being passed has a position of moving after the
    // turn, we have to check the position of where it started
    return collection.pathfinder.isObstacle(
          position.goForward(orientation1),
        ) ||
        collection.pathfinder.isObstacle(
          position.goForward(orientation2),
        );
  }

  @override
  Iterable<AutonomyAStarState> expand() => [
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
          direction: DriveDirection.forwardLeft,
          orientation: orientation.turnQuarterLeft(),
          position: position,
        ),
        copyWith(
          direction: DriveDirection.forwardRight,
          orientation: orientation.turnQuarterRight(),
          position: position,
        ),
      ].where((state) => !collection.pathfinder.isObstacle(state.position) && !drivingThroughObstacle(state));
}
