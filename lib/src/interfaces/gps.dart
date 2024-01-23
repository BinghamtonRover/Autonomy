import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

extension GpsCoordinatesUtils on GpsCoordinates {
  bool get isEmpty => latitude == 0 && longitude == 0;
}

abstract class GpsInterface extends Service {
  final AutonomyInterface collection;
  GpsInterface({required this.collection});
  
  double get longitude => coordinates.longitude;
  double get latitude => coordinates.latitude;

  // ignore: use_setters_to_change_properties
  void update(GpsCoordinates newValue) => coordinates = newValue;
  GpsCoordinates coordinates = GpsCoordinates();
}
