import "package:autonomy/interfaces.dart";
import "package:autonomy/rover.dart";
import "package:autonomy/simulator.dart";

class SensorlessDrive extends DriveInterface {
  SensorlessDrive({required super.collection});
  
  late final simulatedDrive = DriveSimulator(collection: collection);
  late final realDrive = RoverDrive(collection: collection);

  @override
  Future<void> goForward() async {
    await simulatedDrive.goForward();
    await realDrive.goForward();
  }

  @override
  Future<void> stop() async {
    await simulatedDrive.stop();
    await realDrive.stop();
  }

  @override
  Future<void> turnLeft() async {
    await simulatedDrive.turnLeft();
    await realDrive.turnLeft();
  }

  @override
  Future<void> turnRight() async {
    await simulatedDrive.turnRight();
    await realDrive.turnRight();
  }
}
