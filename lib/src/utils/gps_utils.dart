
import "dart:math";

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
  static GpsCoordinates get northEast => north + east;
  static GpsCoordinates get northWest => north + west;
  static GpsCoordinates get southEast => south + east;
  static GpsCoordinates get southWest => south + west;

  static GpsMeters get eastMeters => (lat: 0, long: moveLengthMeters);
  static GpsMeters get westMeters => (lat: 0, long: -moveLengthMeters);
  static GpsMeters get northMeters => (lat: moveLengthMeters, long: 0);
  static GpsMeters get southMeters => (lat: -moveLengthMeters, long: 0);
  static GpsMeters get northEastMeters => northMeters + eastMeters;
  static GpsMeters get northWestMeters => northMeters + westMeters;
  static GpsMeters get southEastMeters => southMeters + eastMeters;
  static GpsMeters get southWestMeters => southMeters + westMeters;

  // Taken from https://stackoverflow.com/a/39540339/9392211
  static const metersPerLatitude = 111.32 * 1000;  // 111.32 km
  static const radiansPerDegree = pi / 180;
  static double get metersPerLongitude => 40075 * cos(GpsInterface.currentLatitude * radiansPerDegree) / 360 * 1000.0;

  static double get latitudePerMeter => 1 / metersPerLatitude;
  static double get longitudePerMeter => 1 / metersPerLongitude;

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
    if (minimumDistance >= moveLengthMeters) {
      distance += (minimumDistance ~/ moveLengthMeters) * sqrt2;
    }

    final translationDelta = (deltaLat - deltaLong).abs();

    if (translationDelta >= moveLengthMeters) {
      distance += translationDelta ~/ moveLengthMeters;
    }

    return distance;
  }

  double manhattanDistance(GpsCoordinates other) {
    final delta = inMeters - other.inMeters;
    return delta.lat.toDouble().abs() + delta.long.abs();
  }

  bool isNear(GpsCoordinates other, [double? tolerance]) {
    tolerance ??= maxErrorMeters;
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
