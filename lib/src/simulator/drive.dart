import "package:autonomy/simulator.dart";
import "package:burt_network/generated.dart";

extension on GpsCoordinates {
  GpsCoordinates operator +(GpsCoordinates other) => GpsCoordinates(
    latitude: latitude + other.latitude,
    longitude: longitude + other.longitude,
  );

  String prettyPrint() => "(lat=$latitude, long=$longitude)";
}

final east = GpsCoordinates(longitude: 1);
final north = GpsCoordinates(latitude: 1);
final west = GpsCoordinates(longitude: -1);
final south = GpsCoordinates(latitude: -1);

class DriveSimulator {
  void handleCommand(DriveCommand command) => switch (command.direction) {
    DriveDirection.DRIVE_DIRECTION_FORWARD => goForward(),
    DriveDirection.DRIVE_DIRECTION_LEFT => turnLeft(),
    DriveDirection.DRIVE_DIRECTION_RIGHT => turnRight(),
    DriveDirection.DRIVE_DIRECTION_STOP => stop(),
    _ => null,
  };

  void goForward() {
    final position = simulator.gps.position.gps;
    final orientation = simulator.imu.orientation.orientation;
    final newPosition = position + switch (orientation.z) {
      0 => north,
      90 => west,
      180 => south,
      270 => east,
      // ignore: flutter_style_todos
      // TODO: Handle *ranges*, not just plain values
      _ => throw StateError("IMU is in invalid orientation: ${orientation.z} degrees"),
    };
    logger.debug("Going forward");
    logger.trace("  Old position: ${position.prettyPrint()}");
    logger.trace("  Orientation: ${orientation.z}");
    logger.trace("  New position: ${newPosition.prettyPrint()}");
    simulator.gps.position = RoverPosition(gps: newPosition);
  }

  void turnLeft() {
    simulator.imu.update(90);
  }

  void turnRight() {
    simulator.imu.update(-90);
  }

  void stop() { }
}
