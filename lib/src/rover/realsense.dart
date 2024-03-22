import "dart:typed_data";

import "package:autonomy/interfaces.dart";

class RoverRealsense extends RealSenseInterface {  
  RoverRealsense({required super.collection});
  
  @override
  Future<bool> init() async {
	hasValue = true;
	return true;
	}
  @override
  Future<void> dispose() async { }
  
  @override
  void updateFrame(Uint16List newFrame) {
    hasValue = true;
    // TODO: Parse depth data
  }
}
