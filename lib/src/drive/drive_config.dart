class DriveConfig {
  final double forwardThrottle;
  final double turnThrottle;
  final Duration turnDelay;
  final Duration oneMeterDelay;

  const DriveConfig({
    required this.forwardThrottle,
    required this.turnThrottle,
    required this.turnDelay,
    required this.oneMeterDelay,
  });
}

const roverConfig = DriveConfig(
  forwardThrottle: 0.1,
  turnThrottle: 0.1,
  oneMeterDelay: Duration(milliseconds: 5500),
  turnDelay: Duration(milliseconds: 4500),
);

const tankConfig = DriveConfig(
  forwardThrottle: 0.3,
  turnThrottle: 0.35,
  turnDelay: Duration(milliseconds: 1000),
  oneMeterDelay: Duration(milliseconds: 2000),
);
