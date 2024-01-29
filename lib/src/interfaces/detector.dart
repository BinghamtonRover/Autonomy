import "service.dart";

abstract class DetectorInterface extends Service {
  void checkObstacles();
  bool canSeeAruco();
  bool isOnSlope();
}
