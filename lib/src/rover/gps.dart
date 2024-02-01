import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

import "corrector.dart";

class RoverGps extends GpsInterface {
  final _latitudeCorrector = ErrorCorrector();
  final _longitudeCorrector = ErrorCorrector();
  RoverGps({required super.collection});
  
  @override
  void update(GpsCoordinates newValue) {
    _latitudeCorrector.addValue(newValue.latitude);
    _longitudeCorrector.addValue(newValue.longitude);
  }

  @override
  GpsCoordinates get coordinates => GpsCoordinates(
    latitude: _latitudeCorrector.calibratedValue,
    longitude: _longitudeCorrector.calibratedValue,
  );
}
