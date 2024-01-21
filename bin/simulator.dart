import "package:autonomy/simulator.dart";

void main() async {  // (lat, long), direction
  await simulator.init();  // (0, 0), North
  await Future<void>.delayed(const Duration(seconds: 1));

  simulator.drive.turnRight();  // (0, 0), East
  await Future<void>.delayed(const Duration(seconds: 1));
  simulator.drive.goForward();  // (0, 1), East
  await Future<void>.delayed(const Duration(seconds: 1));
  simulator.drive.goForward();  // (0, 2), East
  await Future<void>.delayed(const Duration(seconds: 1));

  simulator.drive.turnLeft();  // (0, 2), North
  await Future<void>.delayed(const Duration(seconds: 1));
  simulator.drive.goForward();  // (1, 2), North
  await Future<void>.delayed(const Duration(seconds: 1));
  simulator.drive.goForward();  // (2, 2), North
  await Future<void>.delayed(const Duration(seconds: 1));
  
  simulator.drive.turnLeft();  // (2, 2), West
  await Future<void>.delayed(const Duration(seconds: 1));
  simulator.drive.goForward();  // (2, 1) West
  await Future<void>.delayed(const Duration(seconds: 1));

  simulator.drive.turnRight();
  await Future<void>.delayed(const Duration(seconds: 1));
  simulator.drive.goForward();
  await Future<void>.delayed(const Duration(seconds: 1));

  simulator.server.sendDone();
}
