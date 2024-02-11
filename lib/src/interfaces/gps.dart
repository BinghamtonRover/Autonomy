import "dart:math";

import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

extension RecordToGps on (num, num) {
  GpsCoordinates toGps() => GpsCoordinates(latitude: $1.toDouble(), longitude: $2.toDouble());
}

extension GpsCoordinatesUtils on GpsCoordinates {
  static const epsilon = 0.0001;
  static final east = GpsCoordinates(longitude: 1);
  static final north = GpsCoordinates(latitude: 1);
  static final west = GpsCoordinates(longitude: -1);
  static final south = GpsCoordinates(latitude: -1);
  
  double distanceTo(GpsCoordinates other) => sqrt(
    pow(latitude - other.latitude, 2) +
    pow(longitude - other.longitude, 2),
  );

  double manhattanDistance(GpsCoordinates other) => 
    (latitude - other.latitude).abs() + 
    (longitude - other.longitude).abs();

  bool isNear(GpsCoordinates other) => distanceTo(other).abs() < epsilon;

  GpsCoordinates operator +(GpsCoordinates other) => GpsCoordinates(
    latitude: latitude + other.latitude,
    longitude: longitude + other.longitude,
  );

  String prettyPrint() => "(lat=$latitude, long=$longitude)";

  GpsCoordinates goForward(Orientation orientation) => this + switch(orientation.z) {
    0 => north,
    90 => west,
    180 => south,
    270 => east,
    _ => throw ArgumentError("Unrecognized orientation: $orientation"),
  };

  bool isPast(GpsCoordinates other, Orientation orientation) => switch (orientation.z) {
    0 => latitude >= other.latitude,
    90 => longitude >= other.longitude,
    180 => latitude <= other.latitude,
    270 => longitude <= other.longitude,
    _ => throw ArgumentError("Unrecognized orientation: $orientation"),
  };
}

abstract class GpsInterface extends Service {
  final AutonomyInterface collection;
  GpsInterface({required this.collection});
  
  double get longitude => coordinates.longitude;
  double get latitude => coordinates.latitude;

  void update(GpsCoordinates newValue);
  GpsCoordinates get coordinates;
}
