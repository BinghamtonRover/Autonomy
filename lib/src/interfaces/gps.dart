import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class GpsInterface {
  final AutonomyInterface collection;
  GpsInterface({required this.collection});
  
  double get longitude => coordinates.longitude;
  double get latitude => coordinates.latitude;

  // ignore: use_setters_to_change_properties
  void update(GpsCoordinates newValue) => coordinates = newValue;
  GpsCoordinates coordinates = GpsCoordinates();
}
