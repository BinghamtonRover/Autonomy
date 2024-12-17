
import "dart:math";

import "package:autonomy/interfaces.dart";

extension GpsUtils on GpsCoordinates {
  static double maxErrorMeters = 0.5;
  static double moveLengthMeters = 1;
  static double get epsilonLatitude => maxErrorMeters * latitudePerMeter;
  static double get epsilonLongitude => maxErrorMeters * longitudePerMeter;

  static double get movementLatitude => moveLengthMeters * latitudePerMeter;
  static double get movementLongitude => moveLengthMeters * longitudePerMeter;

  static GpsCoordinates get east => GpsCoordinates(longitude: movementLongitude);
  static GpsCoordinates get west => GpsCoordinates(longitude: -movementLongitude);
  static GpsCoordinates get north => GpsCoordinates(latitude: movementLatitude);
  static GpsCoordinates get south => GpsCoordinates(latitude: -movementLatitude);
  static GpsCoordinates get northEast => GpsCoordinates(latitude: movementLatitude, longitude: movementLongitude);
  static GpsCoordinates get northWest => GpsCoordinates(latitude: movementLatitude, longitude: -movementLongitude);
  static GpsCoordinates get southEast => GpsCoordinates(latitude: -movementLatitude, longitude: movementLongitude);
  static GpsCoordinates get southWest => GpsCoordinates(latitude: -movementLatitude, longitude: -movementLongitude);

  // Taken from https://stackoverflow.com/a/39540339/9392211
  static const metersPerLatitude = 111.32 * 1000;  // 111.32 km
  static const radiansPerDegree = pi / 180;
  static double get metersPerLongitude => 40075 * cos(GpsInterface.currentLatitude * radiansPerDegree) / 360 * 1000.0;

  static double get latitudePerMeter => 1 / metersPerLatitude;
  static double get longitudePerMeter => 1 / metersPerLongitude;

  double distanceTo(GpsCoordinates other) => sqrt(
    pow(latitude - other.latitude, 2) +
    pow(longitude - other.longitude, 2),
  );

  double heuristicDistance(GpsCoordinates other) {
    var steps = 0.0;
    final delta = (this - other).inMeters;
    final deltaLat = delta.lat.abs();
    final deltaLong = delta.long.abs();

    final minimumDistance = min(deltaLat, deltaLong);
    if (minimumDistance >= moveLengthMeters) {
      steps += minimumDistance;
    }

    if (deltaLat < deltaLong) {
      steps += deltaLong - deltaLat;
    } else if (deltaLong < deltaLat) {
      steps += deltaLat - deltaLong;
    }

    return steps;
  }

  double manhattanDistance(GpsCoordinates other) =>
    (latitude - other.latitude).abs() * metersPerLatitude +
    (longitude - other.longitude).abs() * metersPerLongitude;

  bool isNear(GpsCoordinates other, [double? tolerance]) {
    tolerance ??= maxErrorMeters;
    final currentMeters = inMeters;
    final otherMeters = other.inMeters;

    final (deltaX, deltaY) = (
      currentMeters.lat - otherMeters.lat,
      currentMeters.long - otherMeters.long
    );

    final distance = sqrt(pow(deltaX, 2) + pow(deltaY, 2));

    return distance < tolerance;
  }

  GpsCoordinates operator +(GpsCoordinates other) => GpsCoordinates(
    latitude: latitude + other.latitude,
    longitude: longitude + other.longitude,
  );

  GpsCoordinates operator -(GpsCoordinates other) => GpsCoordinates(
    latitude: latitude - other.latitude,
    longitude: longitude - other.longitude,
  );

  String prettyPrint() => toProto3Json().toString();

  GpsCoordinates goForward(CardinalDirection orientation) => this + switch(orientation) {
    CardinalDirection.north => GpsUtils.north,
    CardinalDirection.south => GpsUtils.south,
    CardinalDirection.west => GpsUtils.west,
    CardinalDirection.east => GpsUtils.east,
    CardinalDirection.northEast => GpsUtils.northEast,
    CardinalDirection.northWest => GpsUtils.northWest,
    CardinalDirection.southEast => GpsUtils.southEast,
    CardinalDirection.southWest => GpsUtils.southWest,
  };
}
