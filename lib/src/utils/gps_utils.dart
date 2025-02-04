
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
  static GpsMeters get eastMeters => (lat: 0, long: Constants.moveLengthMeters);
  static GpsMeters get westMeters => (lat: 0, long: -Constants.moveLengthMeters);
  static GpsMeters get northMeters => (lat: Constants.moveLengthMeters, long: 0);
  static GpsMeters get southMeters => (lat: -Constants.moveLengthMeters, long: 0);
  static GpsMeters get northEastMeters => northMeters + eastMeters;
  static GpsMeters get northWestMeters => northMeters + westMeters;
  static GpsMeters get southEastMeters => southMeters + eastMeters;
  static GpsMeters get southWestMeters => southMeters + westMeters;

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

  // GpsCoordinates goForward(CardinalDirection orientation) => this +
  //     switch (orientation) {
  //       CardinalDirection.north => GpsUtils.north,
  //       CardinalDirection.south => GpsUtils.south,
  //       CardinalDirection.west => GpsUtils.west,
  //       CardinalDirection.east => GpsUtils.east,
  //       CardinalDirection.northEast => GpsUtils.northEast,
  //       CardinalDirection.northWest => GpsUtils.northWest,
  //       CardinalDirection.southEast => GpsUtils.southEast,
  //       CardinalDirection.southWest => GpsUtils.southWest,
  //     };

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
