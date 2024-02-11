import "dart:math";
import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

class GpsSimulator extends GpsInterface with ValueReporter {
  final double maxError;
  final _random = Random();

  GpsSimulator({
    required super.collection,
    this.maxError = 0,
  });
  
  @override
  RoverPosition getMessage() => RoverPosition(gps: coordinates);

  GpsCoordinates _coordinates = GpsCoordinates();

  @override
  GpsCoordinates get coordinates => GpsCoordinates(
    latitude: _coordinates.latitude + (_random.nextDouble() * maxError),
    longitude: _coordinates.longitude + (_random.nextDouble() * maxError),
  );

  @override
  void update(GpsCoordinates newValue) => _coordinates = newValue;

  @override
  Future<void> dispose() async {
    _coordinates = GpsCoordinates();
    await super.dispose();
  }
}
