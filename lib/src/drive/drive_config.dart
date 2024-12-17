import "dart:io";

import "package:burt_network/burt_network.dart";

class DriveConfig {
  final double forwardThrottle;
  final double turnThrottle;
  final Duration turnDelay;
  final Duration oneMeterDelay;
  final String subsystemsAddress;

  const DriveConfig({
    required this.forwardThrottle,
    required this.turnThrottle,
    required this.turnDelay,
    required this.oneMeterDelay,
    required this.subsystemsAddress,
  });

  SocketInfo get subsystems => SocketInfo(
    address: InternetAddress(subsystemsAddress),
    port: 8001,
  );
}

const roverConfig = DriveConfig(
  forwardThrottle: 0.1,
  turnThrottle: 0.1,
  oneMeterDelay: Duration(milliseconds: 5500),
  turnDelay: Duration(milliseconds: 4500),
  subsystemsAddress: "192.168.1.20",
);

const tankConfig = DriveConfig(
  forwardThrottle: 0.3,
  turnThrottle: 0.35,
  turnDelay: Duration(milliseconds: 1000),
  oneMeterDelay: Duration(milliseconds: 2000),
  subsystemsAddress: "127.0.0.1",
);
