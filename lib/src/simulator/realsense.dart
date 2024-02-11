import "dart:typed_data";

import "package:autonomy/interfaces.dart";

class RealSenseSimulator extends RealSenseInterface {
  RealSenseSimulator({required super.collection});
  
  @override
  Uint16List depthFrame = Uint16List.fromList([]);

  @override
  void updateFrame(Uint16List newFrame) => depthFrame = newFrame;
}
