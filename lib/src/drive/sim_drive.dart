// ignore_for_file: cascade_invocations

import "package:autonomy/interfaces.dart";

class DriveSimulator extends DriveInterface {
  final bool shouldDelay;
  DriveSimulator({required super.collection, this.shouldDelay = false});

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }

  @override
  Future<void> driveForward(AutonomyAStarState state) async {
    if (shouldDelay) await Future<void>.delayed(const Duration(milliseconds: 500));
    collection.gps.update(state.position);
  }

  @override
  Future<void> faceDirection(CardinalDirection orientation) async {
    if (shouldDelay) await Future<void>.delayed(const Duration(milliseconds: 500));
    collection.imu.update(orientation.orientation);
  }

  @override
  Future<void> stop() async => collection.logger.debug("Stopping");
}
