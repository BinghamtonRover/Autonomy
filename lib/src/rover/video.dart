import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class RoverVideo extends VideoInterface {  
  RoverVideo({required super.collection});

  
  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }
  
  @override
  void updateFrame(VideoData newData) { 
    data = newData;
    // collection.logger.info("Is ArUco detected: ${data.arucoDetected}");
    hasValue  = true;
  }
}
