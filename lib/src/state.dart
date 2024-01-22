import "package:a_star/a_star.dart";

import "package:burt_network/generated.dart";

extension on GpsCoordinates {
  static const epsilon = 5;
  
  double distanceTo(GpsCoordinates other) => 0;

  bool isNear(GpsCoordinates other) => distanceTo(other).abs() < epsilon;

  GpsCoordinates operator +(GpsCoordinates other) => GpsCoordinates(
    latitude: latitude + other.latitude,
    longitude: longitude + other.longitude,
  );
}

final east = GpsCoordinates(longitude: 1);
final north = GpsCoordinates(latitude: 1);
final west = GpsCoordinates(longitude: -1);
final south = GpsCoordinates(latitude: -1);


extension OrientationUtils on Orientation {
  static Orientation clampOrientation(double heading) {
    var adjustedHeading = heading;
    if (heading >= 360) adjustedHeading -= 360;
    if (heading < 0) adjustedHeading = 360 + heading;
    return Orientation(z: adjustedHeading);
  } 

  Orientation turnLeft() => clampOrientation(z + 90);
  Orientation turnRight() => clampOrientation(z - 90);
}

class AutonomyTransition extends AStarTransition<AutonomyState> {
  final DriveCommand command;
  AutonomyTransition(super.parent, {required this.command});
  
  @override
  String toString() => switch(command.direction) {
    DriveDirection.DRIVE_DIRECTION_FORWARD => "Go forward one meter",
    DriveDirection.DRIVE_DIRECTION_LEFT => "Turn left",
    DriveDirection.DRIVE_DIRECTION_RIGHT => "Turn right",
    DriveDirection.DRIVE_DIRECTION_STOP => "Stop",
    _ => "Unknown command",
  };
}

class AutonomyState extends AStarState<AutonomyState> {
  static bool isBlocked(GpsCoordinates coordinates) => false;
  
  final GpsCoordinates position;
  final GpsCoordinates goal;
  final Orientation orientation;
  AutonomyState({
    required this.position, 
    required this.goal, 
    required this.orientation,
    super.depth = 0,
    super.transition,
  });

  @override
  double calculateHeuristic() => position.distanceTo(goal);

  @override
  AutonomyState copy() => AutonomyState(
    position: position, 
    goal: goal,
    orientation: orientation,
    depth: depth + 1,
  );

  @override
  String hash() => "${position.latitude},${position.longitude}-${orientation.z}";

  @override
  bool isGoal() => position.isNear(goal);

  GpsCoordinates goForward() => position + switch(orientation.z) {
    0 => north,
    90 => west,
    180 => south,
    270 => east,
    _ => throw StateError("Unrecognized orientation: $orientation"),
  };

  @override
  Iterable<AutonomyState> getNeighbors() => [
    AutonomyState(  // Turn left
      position: position,
      goal: goal,
      orientation: orientation.turnLeft(),
      depth: depth + 1,
      transition: AutonomyTransition(
        this, 
        command: DriveCommand(direction: DriveDirection.DRIVE_DIRECTION_LEFT),
      ),
    ),
    AutonomyState(  // Turn right
      position: position,
      goal: goal,
      orientation: orientation.turnRight(),
      depth: depth + 1,
      transition: AutonomyTransition(
        this, 
        command: DriveCommand(direction: DriveDirection.DRIVE_DIRECTION_LEFT),
      ),
    ),
    AutonomyState(  // Go forward
      position: goForward(),
      goal: goal,
      orientation: orientation,
      depth: depth + 1,
      transition: AutonomyTransition(
        this, 
        command: DriveCommand(direction: DriveDirection.DRIVE_DIRECTION_LEFT),
      ),
    ),
  ];
}
