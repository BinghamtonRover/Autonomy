import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class RoverDetector extends DetectorInterface {
  RoverDetector({required super.collection});

  @override
  bool isOnSlope() => false;

  @override
  bool findObstacles() => false;

  @override
  bool canSeeAruco() => collection.video.data.arucoDetected == BoolState.YES;

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }
}
