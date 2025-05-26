import "package:autonomy/autonomy.dart";
import "package:autonomy/constants.dart";
import "package:autonomy/interfaces.dart";
import "package:autonomy/src/drive/drive_config.dart";
import "package:autonomy/src/fsm/rover_fsm.dart";
import "package:autonomy/src/utils/behavior_util.dart";
import "package:behavior_tree/behavior_tree.dart";

import "drive_commands.dart";

class SensorForwardState extends RoverState {
  final AutonomyInterface collection;
  final GpsCoordinates position;

  final RoverDriveCommands drive;

  DriveConfig get config => collection.drive.config;

  SensorForwardState(
    super.controller, {
    required this.collection,
    required this.position,
    required this.drive,
  });

  @override
  void update() {
    drive.setThrottle(config.forwardThrottle);
    drive.moveForward();

    if (collection.gps.isNear(position, Constants.intermediateStepTolerance)) {
      controller.popState();
    }
  }

  @override
  void exit() {
    drive.stopMotors();
  }
}

class SensorTurnState extends RoverState {
  final AutonomyInterface collection;
  final Orientation orientation;

  final RoverDriveCommands drive;

  DriveConfig get config => collection.drive.config;

  SensorTurnState(
    super.controller, {
    required this.collection,
    required this.orientation,
    required this.drive,
  });

  @override
  void update() {
    drive.setThrottle(config.turnThrottle);

    final current = collection.imu.heading;
    final target = orientation.heading;
    final error = (target - current).clampHalfAngle();
    if (error < 0) {
      drive.spinRight();
    } else {
      drive.spinLeft();
    }

    if (collection.imu.isNear(orientation)) {
      controller.popState();
    }
  }

  @override
  void exit() {
    drive.stopMotors();
  }
}

/// An implementation of [DriveInterface] that uses the rover's sensors to
/// determine its direction to move in and whether or not it has moved in its
/// desired direction/orientation
///
/// When this is driving, it assumes that the rover is constantly getting new sensor
/// readings, if not, this will continue moving indefinitely
class SensorDrive extends DriveInterface with RoverDriveCommands {
  /// The default period to check for a condition to become true
  static const predicateDelay = Duration(milliseconds: 10);

  /// Default constructor for SensorDrive
  SensorDrive({required super.collection, super.config});

  @override
  StateInterface driveForwardState(GpsCoordinates coordinates) =>
      TimeoutDecorator(
        child: SensorForwardState(
          controller,
          collection: collection,
          position: coordinates,
          drive: this,
        ),
        onTimeout: (controller) => controller.popState(),
        timeout: Constants.driveGPSTimeout,
      );

  @override
  StateInterface faceOrientationState(Orientation orientation) =>
      SensorTurnState(
        controller,
        collection: collection,
        orientation: orientation,
        drive: this,
      );

  @override
  BaseNode driveForwardNode(GpsCoordinates coordinates) => Selector(
    children: [
      Condition(
        () => collection.gps.isNear(
          coordinates,
          Constants.intermediateStepTolerance,
        ),
      ),
      Task(() {
        if (collection.pathfinder.isObstacle(collection.gps.coordinates)) {
          return NodeStatus.failure;
        }
        setThrottle(config.forwardThrottle);
        moveForward();
        return NodeStatus.running;
      }),
    ],
  ).withTimeout(Constants.driveGPSTimeout);

  @override
  BaseNode faceOrientationNode(Orientation orientation) => Selector(
    children: [
      Condition(
        () => collection.imu.isNear(orientation, Constants.turnEpsilon),
      ),
      Task(() {
        setThrottle(config.turnThrottle);
        _tryToFace(orientation);
        return NodeStatus.running;
      }),
    ],
  );

  @override
  BaseNode spinForArucoNode(int arucoId, {CameraName? desiredCamera}) =>
      Selector(
        children: [
          Condition(
            () =>
                collection.video.getArucoDetection(
                  arucoId,
                  desiredCamera: desiredCamera,
                ) !=
                null,
          ),
          Task(() {
            setThrottle(config.turnThrottle);
            spinLeft();
            return NodeStatus.running;
          }),
        ],
      ).withTimeout(Constants.arucoSearchTimeout);

  @override
  Future<bool> stop() async {
    stopMotors();
    return true;
  }

  /// Will periodically check for a condition to become true. This can be
  /// thought of as a "wait until", where the rover will periodically check
  /// if it has reached its desired position or orientation.
  ///
  /// The [predicate] method is intended to manuever the rover until its condition
  /// becomes true. To prevent infinite driving, this will return false if either
  /// the command is canceled, or [stopNearObstacle] is true and the rover becomes
  /// too close to an obstacle.
  ///
  /// Returns whether or not the feedback loop reached its desired state.
  Future<bool> runFeedback(
    bool Function() predicate, {
    bool stopNearObstacle = false,
  }) async {
    while (true) {
      if (collection.orchestrator.currentCommand == null) {
        return false;
      }
      if (stopNearObstacle &&
          collection.pathfinder.isObstacle(collection.gps.coordinates)) {
        return false;
      }

      if (predicate()) {
        return true;
      }

      await Future<void>.delayed(predicateDelay);
    }
  }

  @override
  Future<bool> init() async => true;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> driveForward(GpsCoordinates position) async {
    collection.logger.info("Driving forward one meter");
    setThrottle(config.forwardThrottle);
    var succeeded = true;
    succeeded = await runFeedback(() {
      if (!succeeded) return true;
      moveForward();
      return collection.gps.isNear(
        position,
        Constants.intermediateStepTolerance,
      );
      // ignore: require_trailing_commas
    }, stopNearObstacle: true).timeout(
      Constants.driveGPSTimeout,
      onTimeout: () {
        collection.logger.warning(
          "GPS Drive timed out",
          body:
              "Failed to reach ${position.prettyPrint()} after ${Constants.driveGPSTimeout}",
        );
        return false;
      },
    );
    await stop();
    return succeeded;
  }

  @override
  Future<bool> faceOrientation(Orientation orientation) async {
    collection.logger.info("Turning to face $orientation...");
    setThrottle(config.turnThrottle);
    final result = await runFeedback(() => _tryToFace(orientation));
    await stop();
    return result;
  }

  bool _tryToFace(Orientation orientation) {
    final current = collection.imu.heading;
    final target = orientation.heading;
    final error = (target - current).clampHalfAngle();
    if (error < 0) {
      spinRight();
    } else {
      spinLeft();
    }
    // if (error.abs() < 180) {
    //   if (current < target) {
    //     spinRight();
    //   } else {
    //     spinLeft();
    //   }
    // } else {
    //   if (current < target) {
    //     spinLeft();
    //   } else {
    //     spinRight();
    //   }
    // }
    collection.logger.trace("Current heading: $current");
    return collection.imu.isNear(orientation);
  }

  @override
  Future<bool> spinForAruco(int arucoId, {CameraName? desiredCamera}) async {
    setThrottle(config.turnThrottle);
    var foundAruco = true;
    foundAruco = await runFeedback(() {
      if (!foundAruco) {
        return true;
      }
      spinLeft();
      return collection.video.getArucoDetection(
            arucoId,
            desiredCamera: desiredCamera,
          ) !=
          null;
    }).timeout(
      Constants.arucoSearchTimeout,
      onTimeout: () {
        foundAruco = false;
        return false;
      },
    );
    await stop();
    return foundAruco;
  }

  @override
  Future<void> approachAruco() async {
    // const sizeThreshold = 0.2;
    // const epsilon = 0.00001;
    // setThrottle(config.forwardThrottle);
    // moveForward();
    // await waitFor(() {
    //   final size = collection.video.arucoSize;
    //   collection.logger.trace("The Aruco tag is at $size percent");
    //   return true;
    //   return (size.abs() < epsilon && !collection.detector.canSeeAruco()) || size >= sizeThreshold;
    // }).timeout(config.oneMeterDelay * 5);
    await stop();
  }
}
