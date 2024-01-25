import "package:a_star/a_star.dart";

import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

class AutonomyTransition extends AStarTransition<AutonomyAStarState> {
  final DriveDirection direction;
  AutonomyTransition(super.parent, {required this.direction});
  AutonomyTransition.simulated({required GpsCoordinates position, required Orientation orientation, required this.direction, required AutonomyInterface collection}) : 
    super(AutonomyAStarState(position: position, orientation: orientation, goal: GpsCoordinates(), collection: collection));

  GpsCoordinates get position => parent.position;
  Orientation get orientation => parent.orientation;
  
  @override
  String toString() => switch(direction) {
    DriveDirection.DRIVE_DIRECTION_FORWARD => "Go forward one meter",
    DriveDirection.DRIVE_DIRECTION_LEFT => "Turn left",
    DriveDirection.DRIVE_DIRECTION_RIGHT => "Turn right",
    DriveDirection.DRIVE_DIRECTION_STOP => "Stop",
    _ => "Unknown command",
  };
}

class AutonomyAStarState extends AStarState<AutonomyAStarState> {
  final GpsCoordinates position;
  final GpsCoordinates goal;
  final Orientation orientation;
  final AutonomyInterface collection;
  AutonomyAStarState({
    required this.position, 
    required this.goal, 
    required this.orientation,
    required this.collection,
    super.depth = 0,
    super.transition,
  });

  @override
  double calculateHeuristic() => position.distanceTo(goal);

  @override
  String hash() => "${position.latitude},${position.longitude}-${orientation.z}";

  @override
  bool isGoal() => position.isNear(goal);

  AutonomyAStarState copyWith(DriveDirection direction, {GpsCoordinates? position, Orientation? orientation}) => AutonomyAStarState(
    position: position ?? this.position, 
    orientation: orientation ?? this.orientation,
    goal: goal, 
    depth: depth + 1,
    collection: collection,
    transition: AutonomyTransition(this, direction: direction),
  )..finalize();

  @override
  Iterable<AutonomyAStarState> getNeighbors() => [
    copyWith(DriveDirection.DRIVE_DIRECTION_LEFT, orientation: orientation.turnLeft()),
    copyWith(DriveDirection.DRIVE_DIRECTION_RIGHT, orientation: orientation.turnRight()),
    copyWith(DriveDirection.DRIVE_DIRECTION_FORWARD, position: position.goForward(orientation)),
  ].where((state) => !collection.pathfinder.isObstacle(state.position));
}
