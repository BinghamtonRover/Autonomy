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

enum DriveOrientation {
  north(0),
  west(90),
  south(180),
  east(270),
  northEast(360 - 45),
  northWest(45),
  southEast(180 + 45),
  southWest(180 - 45);

  final int angle;
  const DriveOrientation(this.angle);

  Orientation get orientation => Orientation(z: angle.toDouble());

  static DriveOrientation? fromRaw(Orientation orientation) {
    // TODO: Make this more precise.
    for (final value in values) {
      if (orientation.isNear(value.angle.toDouble(), OrientationUtils.orientationEpsilon)) return value;
    }
    return null;
  }

  static DriveOrientation nearest(Orientation orientation) {
    var smallestDiff = double.infinity;
    var closestOrientation = DriveOrientation.north;

    for (final value in values) {
      var diff = value.angle.toDouble() - orientation.z;
      if (diff < -180) {
        diff += 360;
      } else if (diff > 180) {
        diff -= 360;
      }

      if (diff.abs() < smallestDiff) {
        smallestDiff = diff.abs();
        closestOrientation = value;
      }
    }

    return closestOrientation;
  }

  bool get isPerpendicular => angle.abs() % 90 == 0;

  DriveOrientation turnLeft() => switch (this) {
    north => west,
    west => south,
    south => east,
    east => north,
    northEast => northWest,
    northWest => southWest,
    southWest => southEast,
    southEast => northEast,
  };

  DriveOrientation turnRight() => switch (this) {
    north => east,
    west => north,
    south => west,
    east => south,
    northEast => southEast,
    southEast => southWest,
    southWest => northWest,
    northWest => northEast,
  };

  DriveOrientation turnQuarterLeft() => switch (this) {
    north => northWest,
    northWest => west,
    west => southWest,
    southWest => south,
    south => southEast,
    southEast => east,
    east => northEast,
    northEast => north,
  };

  DriveOrientation turnQuarterRight() => switch (this) {
    north => northEast,
    northEast => east,
    east => southEast,
    southEast => south,
    south => southWest,
    southWest => west,
    west => northWest,
    northWest => north,
  };
}

abstract class DriveInterface extends Service {
  AutonomyInterface collection;
  DriveOrientation orientation = DriveOrientation.north;
  DriveInterface({required this.collection});

  Future<void> stop();

  Future<void> driveForward(AutonomyAStarState state);

  Future<void> turn(AutonomyAStarState state) => faceDirection(state.endOrientation);

  Future<void> faceNorth() => faceDirection(DriveOrientation.north);

  Future<void> faceDirection(DriveOrientation orientation) async {
    this.orientation = orientation;
  }

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
