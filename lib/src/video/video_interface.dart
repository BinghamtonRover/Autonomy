import "package:autonomy/constants.dart";
import "package:autonomy/interfaces.dart";

/// Handles obstacle detection data and ArUco data from video
abstract class VideoInterface extends Service with Receiver {
  bool flag = false;

  final AutonomyInterface collection;
  VideoInterface({required this.collection});

  void updateFrame(VisionResult result);

  DetectedObject? getArucoDetection(int id, {CameraName? desiredCamera}) => null;

  Future<DetectedObject?> waitForAruco(
    int id, {
    CameraName? desiredCamera,
    Duration timeout = Constants.arucoSearchTimeout,
  }) =>
      Future.value();
}
