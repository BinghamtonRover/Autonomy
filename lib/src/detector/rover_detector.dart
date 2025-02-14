import "package:autonomy/interfaces.dart";

class RoverDetector extends DetectorInterface {
  RoverDetector({required super.collection});

  @override
  bool isOnSlope() => false;

  @override
  bool findObstacles() => false;

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }
}
