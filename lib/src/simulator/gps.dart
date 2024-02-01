import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

import "reporter.dart";

class GpsSimulator extends GpsInterface with ValueReporter {
  GpsSimulator({required super.collection});
  
  @override
  RoverPosition getMessage() => RoverPosition(gps: coordinates);

  GpsCoordinates _coordinates = GpsCoordinates();

  @override
  GpsCoordinates get coordinates => _coordinates;

  @override
  void update(GpsCoordinates newValue) => _coordinates = newValue;
}
