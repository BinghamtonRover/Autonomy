
import "dart:math";

import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

extension GpsUtils on GpsCoordinates {
  static double maxErrorMeters = 1;
  static double moveLengthMeters = 1;
  static double get epsilonLatitude => maxErrorMeters * latitudePerMeter; 
  static double get epsilonLongitude => maxErrorMeters * longitudePerMeter;

  static double get movementLatitude => moveLengthMeters * latitudePerMeter; 
  static double get movementLongitude => moveLengthMeters * longitudePerMeter;

  static GpsCoordinates get east => GpsCoordinates(longitude: -movementLongitude);
  static GpsCoordinates get west => GpsCoordinates(longitude: movementLongitude);
  static GpsCoordinates get north => GpsCoordinates(latitude: movementLatitude);
  static GpsCoordinates get south => GpsCoordinates(latitude: -movementLatitude);
  static GpsCoordinates get northEast => GpsCoordinates(latitude: movementLatitude, longitude: -movementLongitude);
  static GpsCoordinates get northWest => GpsCoordinates(latitude: movementLatitude, longitude: movementLongitude);
  static GpsCoordinates get southEast => GpsCoordinates(latitude: -movementLatitude, longitude: -movementLongitude);
  static GpsCoordinates get southWest => GpsCoordinates(latitude: -movementLatitude, longitude: movementLongitude);

  // Taken from https://stackoverflow.com/a/39540339/9392211
  static const metersPerLatitude = 111.32 * 1000;  // 111.32 km
  // static const metersPerLatitude = 1;
  static const radiansPerDegree = pi / 180;
  static double get metersPerLongitude => 40075 * cos(GpsInterface.currentLatitude * radiansPerDegree) / 360 * 1000.0;
  
  static double get latitudePerMeter => 1 / metersPerLatitude;
  static double get longitudePerMeter => 1 / metersPerLongitude;
  
  double distanceTo(GpsCoordinates other) => sqrt(
    pow(latitude - other.latitude, 2) +
    pow(longitude - other.longitude, 2),
  );

  double manhattanDistance(GpsCoordinates other) => 
    (latitude - other.latitude).abs() * metersPerLatitude + 
    (longitude - other.longitude).abs() * metersPerLongitude;

  bool isNear(GpsCoordinates other, [double? tolerance]) {
    tolerance ??= maxErrorMeters;
    return (latitude - other.latitude).abs() < tolerance * latitudePerMeter &&
        (longitude - other.longitude).abs() < tolerance * longitudePerMeter;
  }

  GpsCoordinates operator +(GpsCoordinates other) => GpsCoordinates(
    latitude: latitude + other.latitude,
    longitude: longitude + other.longitude,
  );

//  String prettyPrint() => "(lat=${(latitude * GpsUtils.metersPerLatitude).toStringAsFixed(2)}, long=${(longitude * GpsUtils.metersPerLongitude).toStringAsFixed(2)})";
  String prettyPrint() => toProto3Json().toString();

  GpsCoordinates goForward(DriveOrientation orientation) => this + switch(orientation) {
    DriveOrientation.north => GpsUtils.north,
    DriveOrientation.south => GpsUtils.south,
    DriveOrientation.west => GpsUtils.west,
    DriveOrientation.east => GpsUtils.east,
    DriveOrientation.northEast => GpsUtils.northEast,
    DriveOrientation.northWest => GpsUtils.northWest,
    DriveOrientation.southEast => GpsUtils.southEast,
    DriveOrientation.southWest => GpsUtils.southWest,
  };
}
