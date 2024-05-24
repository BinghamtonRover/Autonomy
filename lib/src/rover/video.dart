import "package:autonomy/interfaces.dart";
import "dart:async";
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
	if (data.arucoDetected == BoolState.YES) {
		flag = true;
		Timer(Duration(seconds: 3), () => flag = false);
	}
    collection.logger.info("Is ArUco detected: ${data.arucoDetected}");
    hasValue  = true;
  }
}
