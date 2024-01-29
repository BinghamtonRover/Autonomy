import "package:autonomy/interfaces.dart";

class DetectorSimulator extends DetectorInterface {  
  static const arucoPosition = (10, 10);
  static const slopedLatitude = -5;

  final AutonomyInterface collection;
  DetectorSimulator({required this.collection});
  
  @override
  void checkObstacles() {
    
  }

  @override
  bool canSeeAruco() => false;  // if can see [arucoPosition]

  @override
  bool isOnSlope() => false;  // if on [slopedLatitude]
}
