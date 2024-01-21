import "dart:async";
import "package:autonomy/simulator.dart";
import "package:burt_network/generated.dart";

class ImuSimulator {
  static const reportInterval = Duration(milliseconds: 250);
  
  RoverPosition orientation = RoverPosition(
    orientation: Orientation(z: 0),
  );

  Timer? timer;
  double get heading => orientation.orientation.z;

  Future<void> init() async { 
    timer = Timer.periodic(reportInterval, (timer) => reportOrientation());
  }

  void dispose() => timer?.cancel();

  void reportOrientation() {
    simulator.server.sendMessage(orientation);
  }

  void update(int offset) {
    var newValue = heading + offset;
    if (newValue < 0) newValue = 360 + newValue;
    if (newValue >= 360) newValue = newValue - 360;
    orientation.orientation.z = newValue;
  }
}
