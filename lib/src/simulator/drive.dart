// ignore_for_file: cascade_invocations

import "package:autonomy/interfaces.dart";
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

class DriveSimulator extends DriveInterface {
  DriveSimulator({required super.collection});

  @override
  Future<void> goForward() async {
    final position = collection.gps.coordinates;
    final heading = collection.imu.heading;
    final newPosition = position + switch (heading) {
      0 => north,
      90 => west,
      180 => south,
      270 => east,
      // ignore: flutter_style_todos
      // TODO: Handle *ranges*, not just plain values
      _ => throw StateError("IMU is in invalid orientation: $heading degrees"),
    };
    collection.logger.debug("Going forward");
    collection.logger.trace("  Old position: ${position.prettyPrint()}");
    collection.logger.trace("  Orientation: $heading");
    collection.logger.trace("  New position: ${newPosition.prettyPrint()}");
    collection.gps.update(newPosition);
  }

  @override
  Future<void> turnLeft() async  {
    collection.logger.debug("Turning left");
    final heading = collection.imu.heading;
    final orientation = Orientation(z: heading + 90);
    collection.imu.update(orientation);
  }

  @override
  Future<void> turnRight() async  {
    collection.logger.debug("Turning right");
    final heading = collection.imu.heading;
    final orientation = Orientation(z: heading - 90);
    collection.imu.update(orientation);
  }

  @override
  Future<void> stop() async => collection.logger.debug("Stopping");
}
