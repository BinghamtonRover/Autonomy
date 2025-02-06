
import "dart:math";

import "package:autonomy/constants.dart";
import "package:autonomy/interfaces.dart";

/// An alias for gps coordinates measured in meters
typedef GpsMeters = ({num lat, num long});

/// Utility math methods for GpsMeters
extension GpsMetersUtil on GpsMeters {
  /// Add 2 [GpsMeters] together
  GpsMeters operator +(GpsMeters other) => (
        lat: lat + other.lat,
        long: long + other.long,
      );

  /// Subtract 2 [GpsMeters] from each other
  GpsMeters operator -(GpsMeters other) => (
        lat: lat - other.lat,
        long: long - other.long,
      );
}

extension GpsUtils on GpsCoordinates {
  static const GpsMeters eastMeters = (lat: 0, long: Constants.moveLengthMeters);
  static const GpsMeters westMeters = (lat: 0, long: -Constants.moveLengthMeters);
  static const GpsMeters northMeters = (lat: Constants.moveLengthMeters, long: 0);
  static const GpsMeters southMeters = (lat: -Constants.moveLengthMeters, long: 0);
  static final GpsMeters northEastMeters = northMeters + eastMeters;
  static final GpsMeters northWestMeters = northMeters + westMeters;
  static final GpsMeters southEastMeters = southMeters + eastMeters;
  static final GpsMeters southWestMeters = southMeters + westMeters;

  double distanceTo(GpsCoordinates other) {
    final deltaMeters = inMeters - other.inMeters;

    return sqrt(pow(deltaMeters.long, 2) + pow(deltaMeters.lat, 2));
  }

  double heuristicDistance(GpsCoordinates other) {
    var distance = 0.0;
    final delta = inMeters - other.inMeters;
    final deltaLat = delta.lat.abs();
    final deltaLong = delta.long.abs();

    final minimumDistance = min(deltaLat, deltaLong);
    if (minimumDistance >= Constants.moveLengthMeters) {
      distance += (minimumDistance ~/ Constants.moveLengthMeters) * sqrt2;
    }

    final translationDelta = (deltaLat - deltaLong).abs();

    if (translationDelta >= Constants.moveLengthMeters) {
      distance += translationDelta ~/ Constants.moveLengthMeters;
    }

    return distance;
  }

  double manhattanDistance(GpsCoordinates other) {
    final delta = inMeters - other.inMeters;
    return delta.lat.toDouble().abs() + delta.long.abs();
  }

  double octileDistance(GpsCoordinates other) {
    final delta = inMeters - other.inMeters;
    final dx = delta.long.abs() ~/ Constants.moveLengthMeters;
    final dy = delta.lat.abs() ~/ Constants.moveLengthMeters;

    return max(dx, dy) + (sqrt2 - 1) * min(dx, dy);
  }

  bool isNear(GpsCoordinates other, [double? tolerance]) {
    tolerance ??= Constants.maxErrorMeters;
    final currentMeters = inMeters;
    final otherMeters = other.inMeters;

    final delta = currentMeters - otherMeters;

    final distance = sqrt(pow(delta.long, 2) + pow(delta.lat, 2));

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

  GpsCoordinates goForward(CardinalDirection orientation) => (inMeters +
    switch (orientation) {
      CardinalDirection.north => GpsUtils.northMeters,
      CardinalDirection.south => GpsUtils.southMeters,
      CardinalDirection.west => GpsUtils.westMeters,
      CardinalDirection.east => GpsUtils.eastMeters,
      CardinalDirection.northEast => GpsUtils.northEastMeters,
      CardinalDirection.northWest => GpsUtils.northWestMeters,
      CardinalDirection.southEast => GpsUtils.southEastMeters,
      CardinalDirection.southWest => GpsUtils.southWestMeters,
    }).toGps();
}
