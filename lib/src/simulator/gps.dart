import "dart:async";
import "package:autonomy/simulator.dart";
import "package:burt_network/generated.dart";

class GpsSimulator {
  static const reportInterval = Duration(milliseconds: 250);
  
  RoverPosition position = RoverPosition(
    gps: GpsCoordinates(latitude: 0, longitude: 0),
  );

  Timer? timer;

  Future<void> init() async { 
    timer = Timer.periodic(reportInterval, (timer) => reportPosition());
  }

  void dispose() => timer?.cancel();

  void reportPosition() {
    // logger.trace("Sending lat=${position.gps.latitude}, long=${position.gps.longitude}");
    simulator.server.sendMessage(position);
  }
}
