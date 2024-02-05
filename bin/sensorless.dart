import "package:burt_network/logging.dart";
import "package:autonomy/simulator.dart";

void main() async {
    Logger.level = LogLevel.info;
    final simulator = AutonomySimulator();
    simulator.drive = SensorlessDrive(collection: simulator);
    await simulator.init();
    await simulator.server.waitForConnection();

    // "Snakes" around a 3x3 meter box.    (0, 0), North
    await simulator.drive.goForward();  // (1, 0), North
    await simulator.drive.goForward();  // (2, 0), North
    await simulator.drive.turnRight();  // (2, 0), East
    await simulator.drive.goForward();  // (2, 1), East
    await simulator.drive.turnRight();  // (2, 1), South
    await simulator.drive.goForward();  // (1, 1), South
    await simulator.drive.goForward();  // (0, 1), South
    await simulator.drive.turnLeft();   // (0, 1), East
    await simulator.drive.goForward();  // (0, 2), East
    await simulator.drive.turnLeft();   // (0, 2), North
    await simulator.drive.goForward();  // (1, 2), North
    await simulator.drive.goForward();  // (2, 2), North
    await simulator.drive.turnLeft();   // (2, 2), West
    await simulator.drive.goForward();  // (2, 1), West
    await simulator.drive.goForward();  // (2, 0), West
    await simulator.drive.turnLeft();   // (2, 0), South
    await simulator.drive.goForward();  // (1, 0), South
    await simulator.drive.goForward();  // (0, 0), South
    await simulator.drive.turnLeft();   // (0, 0), East
    await simulator.drive.turnLeft();   // (0, 0), North

    await simulator.dispose();
}
