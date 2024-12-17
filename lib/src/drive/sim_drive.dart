import "package:autonomy/interfaces.dart";

class DriveSimulator extends DriveInterface {
  static const delay = Duration(milliseconds: 500);

  final bool shouldDelay;
  DriveSimulator({required super.collection, this.shouldDelay = false, super.config});

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }

  @override
  Future<void> driveForward(GpsCoordinates position) async {
    if (shouldDelay) await Future<void>.delayed(delay);
    collection.gps.update(position);
  }

  @override
  Future<void> faceDirection(CardinalDirection orientation) async {
    if (shouldDelay) await Future<void>.delayed(const Duration(milliseconds: 500));
    collection.imu.update(orientation.orientation);
  }

  @override
  Future<void> stop() async => collection.logger.debug("Stopping");
}
