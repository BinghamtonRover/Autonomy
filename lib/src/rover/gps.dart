import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

import "corrector.dart";

class RoverGps extends GpsInterface {
  final _latitudeCorrector = ErrorCorrector(maxSamples: 1, maxDeviation: GpsInterface.gpsError * 10);
  final _longitudeCorrector = ErrorCorrector(maxSamples: 1, maxDeviation: GpsInterface.gpsError * 10);
  RoverGps({required super.collection});
    
  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async {
    _latitudeCorrector.clear();
    _longitudeCorrector.clear();
  }

	GpsCoordinates _coordinates = GpsCoordinates();  

	@override
  void update(GpsCoordinates newValue) {
    _latitudeCorrector.addValue(newValue.latitude);
    _longitudeCorrector.addValue(newValue.longitude);
	_coordinates = newValue;
    hasValue = true;
  }

  @override
  GpsCoordinates get coordinates => _coordinates;
//  GpsCoordinates get coordinates => GpsCoordinates(
//    latitude: _latitudeCorrector.calibratedValue,
//    longitude: _longitudeCorrector.calibratedValue,
//  );
}
