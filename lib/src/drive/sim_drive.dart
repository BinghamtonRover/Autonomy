import "package:autonomy/interfaces.dart";
import "package:autonomy/src/utils/behavior_util.dart";
import "package:behavior_tree/behavior_tree.dart";

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
  DriveSimulator({required super.collection, this.shouldDelay = false, super.config});

  BaseNode _delayAndExecute({
    required Duration delay,
    required BaseNode child,
  }) => Sequence(children: [DelayedNode(delay), child]);

  @override
  BaseNode driveForwardNode(GpsCoordinates coordinates) {
    final updateGps = Task(() {
      collection.gps.update(coordinates);
      return NodeStatus.success;
    });
    return ConditionalNode(
      condition: () => shouldDelay,
      onTrue: _delayAndExecute(delay: delay, child: updateGps),
      onFalse: updateGps,
    );
  }

  @override
  BaseNode faceOrientationNode(Orientation orientation) {
    final updateImu = Task(() {
      collection.imu.update(orientation);
      return NodeStatus.success;
    });
    return ConditionalNode(
      condition: () => shouldDelay,
      onTrue: _delayAndExecute(delay: delay, child: updateImu),
      onFalse: updateImu,
    );
  }

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async { }

  @override
  Future<bool> driveForward(GpsCoordinates position) async {
    if (shouldDelay) await Future<void>.delayed(delay);
    collection.gps.update(position);
    return true;
  }

  @override
  Future<bool> faceOrientation(Orientation orientation) async {
    if (shouldDelay) await Future<void>.delayed(const Duration(milliseconds: 500));
    collection.imu.update(orientation);
    return true;
  }

  @override
  Future<bool> spinForAruco(int arucoId, {CameraName? desiredCamera}) async => true;

  @override
  Future<bool> stop() async {
    collection.logger.debug("Stopping");
    return true;
  }
}
