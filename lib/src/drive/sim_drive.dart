import "package:autonomy/interfaces.dart";

/// An implementation of [DriveInterface] that will not move the rover,
/// and only update its sensor readings based on the desired values
///
/// This assumes that the implementations for sensors are not expected to be updated from the rover,
/// otherwise, this can cause the rover to not follow its path properly
class DriveSimulator extends DriveInterface {
  /// The amount of time to wait before updating the virtual sensor readings
  static const delay = Duration(milliseconds: 500);

  /// Whether or not to wait before updating virtual sensor readings,
  /// this can be useful when simulating the individual steps of a path
  final bool shouldDelay;

  /// Constructor for DriveSimulator, initializing the default fields, and whether or not it should delay
  DriveSimulator({
    required super.collection,
    this.shouldDelay = false,
    super.config,
  });

  RoverState _delayAndExecuteState({
    required Duration delay,
    required StateInterface child,
  }) => SequenceState(
    child.controller,
    steps: [
      DelayedState(child.controller, delayTime: delay),
      child,
    ],
  );

  @override
  StateInterface driveForwardState(GpsCoordinates coordinates) =>
      _delayAndExecuteState(
        delay: shouldDelay ? delay : Duration.zero,
        child: FunctionalState(
          controller,
          onUpdate: (controller) {
            collection.gps.update(coordinates);
            controller.popState();
          },
        ),
      );

  @override
  StateInterface faceOrientationState(Orientation orientation) =>
      _delayAndExecuteState(
        delay: shouldDelay ? delay : Duration.zero,
        child: FunctionalState(
          controller,
          onUpdate: (controller) {
            collection.imu.update(orientation);
            controller.popState();
          },
        ),
      );

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> driveForward(GpsCoordinates position) async {
    if (shouldDelay) await Future<void>.delayed(delay);
    collection.gps.update(position);
    return true;
  }

  @override
  Future<bool> faceOrientation(Orientation orientation) async {
    if (shouldDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    collection.imu.update(orientation);
    return true;
  }

  @override
  Future<bool> spinForAruco(int arucoId, {CameraName? desiredCamera}) async =>
      true;

  @override
  Future<bool> stop() async {
    collection.logger.debug("Stopping");
    return true;
  }
}
