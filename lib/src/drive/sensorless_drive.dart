import "package:autonomy/rover.dart";
import "package:autonomy/simulator.dart";

class SensorlessDrive extends RoverDrive {
  SensorlessDrive({
    required super.collection,
    super.useGps = false,
    super.useImu = false,
  }) : super(simDrive: DriveSimulator(collection: collection));
}
