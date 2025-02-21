import "dart:math";

import "package:autonomy/constants.dart";
import "package:autonomy/interfaces.dart";
import "dart:async";

import "package:coordinate_converter/coordinate_converter.dart";

class RoverOrchestrator extends OrchestratorInterface with ValueReporter {
  final List<GpsCoordinates> traversed = [];
  List<AutonomyAStarState>? currentPath;
  RoverOrchestrator({required super.collection});

  @override
  Future<void> dispose() async {
    currentPath = null;
    currentCommand = null;
    currentState = AutonomyState.AUTONOMY_STATE_UNDEFINED;
    traversed.clear();
    await super.dispose();
  }

  @override
  AutonomyData get statusMessage => AutonomyData(
    destination: currentCommand?.destination,
    state: currentState,
    obstacles: collection.pathfinder.obstacles,
    path: [
      for (final transition in currentPath ?? <AutonomyAStarState>[])
        transition.position,
      ...traversed,
    ],
    task: currentCommand?.task,
    crash: false,  // TODO: Investigate if this is used and how to use it better
  );

  @override
  Message getMessage() => statusMessage;

  bool findAndLockObstacles() {
    if (!collection.detector.findObstacles()) {
      return false;
    }

    if (currentPath == null) return true;

    currentPath!
        .map((state) => state.position)
        .where((position) => collection.pathfinder.isObstacle(position))
        .forEach(collection.pathfinder.lockObstacle);

    return true;
  }

  Future<bool> calculateAndFollowPath(
    GpsCoordinates goal, {
    bool abortOnError = true,
    bool Function()? alternateEndCondition,
  }) async {
    await collection.drive.resolveOrientation();
    collection.detector.findObstacles();
    while (!collection.gps.coordinates.isNear(goal) && !(alternateEndCondition?.call() ?? false)) {
      // Calculate a path
      collection.logger.debug("Finding a path");
      currentState = AutonomyState.PATHING;
      final path = collection.pathfinder.getPath(goal);
      currentPath = path;  // also use local variable path for promotion
      if (path == null) {
        final current = collection.gps.coordinates;
        collection.logger.error("Could not find a path", body: "No path found from ${current.prettyPrint()} to ${goal.prettyPrint()}");
        if (abortOnError) {
          currentState = AutonomyState.NO_SOLUTION;
          currentCommand = null;
        }
        return false;
      }
      // Try to take that path
      final current = collection.gps.coordinates;
      collection.logger.debug("Found a path from ${current.prettyPrint()} to ${goal.prettyPrint()}: ${path.length} steps");
      collection.logger.debug("Here is a summary of the path");
      for (final step in path) {
        collection.logger.debug(step.toString());
      }
      currentState = AutonomyState.DRIVING;
      var count = 0;
      for (final state in path) {
        collection.logger.debug(state.toString());
        // Alternate end condition may have hit between steps
        if (alternateEndCondition?.call() ?? false) {
          break;
        }
        // Replan if too far from start point
        final distanceError = collection.gps.coordinates.distanceTo(state.startPostition);
        if (distanceError >= Constants.replanErrorMeters) {
          collection.logger.info("Replanning Path", body: "Rover is $distanceError meters off the path");
          findAndLockObstacles();
          break;
        }
        // Re-align to desired start orientation if angle is too far
        if (state.instruction == DriveDirection.forward) {
          Orientation targetOrientation;
          // if it has RTK, point towards the next coordinate
          if (collection.gps.coordinates.hasRTK) {
            final difference = state.position.asUtmCoordinates - collection.gps.coordinates.asUtmCoordinates;

            final angle = atan2(difference.y, difference.x) * 180 / pi;

            targetOrientation = Orientation(z: angle);
          } else {
            targetOrientation = state.orientation.orientation;
          }

          if (!collection.imu.isNear(
            targetOrientation,
            Constants.driveRealignmentEpsilon,
          )) {
            collection.logger.info("Re-aligning IMU to correct orientation");
            await collection.drive.faceOrientation(targetOrientation);
          }
        }
        // If there was an error (usually a timeout) while driving, replan path
        if (!await collection.drive.driveState(state)) {
          findAndLockObstacles();
          break;
        }
        if (currentCommand == null || currentPath == null) {
          collection.logger.info("Aborting path, command was canceled");
          return false;
        }
        traversed.add(state.position);
        // if (state.direction != DriveDirection.forward) continue;
        if (++count >= 5) {
          findAndLockObstacles();
          break;
        }
        final foundObstacle = findAndLockObstacles();
        if (foundObstacle) {
          collection.logger.debug("Found an obstacle. Recalculating path...");
          break;  // calculate a new path
        }
      }
    }
    return true;
  }

  @override
  Future<void> handleGpsTask(AutonomyCommand command) async {
    final destination = command.destination;
    collection.logger.info("Received GPS Task", body: "Go to ${destination.prettyPrint()}");
    collection.logger.debug("Currently at ${collection.gps.coordinates.prettyPrint()}");
    traversed.clear();
    collection.drive.setLedStrip(ProtoColor.RED);
    // detect obstacles before and after resolving orientation, as a "scan"
    collection.detector.findObstacles();
    await collection.drive.resolveOrientation();
    collection.detector.findObstacles();

    if (!await calculateAndFollowPath(command.destination)) {
      return;
    }

    collection.logger.info("Task complete");
    collection.drive.setLedStrip(ProtoColor.GREEN, blink: true);
    currentState = AutonomyState.AT_DESTINATION;
    currentCommand = null;
  }

  @override
  Future<void> handleArucoTask(AutonomyCommand command) async {
    collection.drive.setLedStrip(ProtoColor.RED);

    // Go to GPS coordinates
    collection.logger.info("Got ArUco Task");
    if (command.destination != GpsCoordinates(latitude: 0, longitude: 0)) {
      if (!await calculateAndFollowPath(command.destination, abortOnError: false)) {
        collection.logger.error("Failed to follow path towards initial destination");
        currentState = AutonomyState.NO_SOLUTION;
        currentCommand = null;
        return;
      }
    }

    currentState = AutonomyState.SEARCHING;
    collection.logger.info("Searching for ArUco tag");
    final didSeeAruco = await collection.drive.spinForAruco(
      command.arucoId,
      desiredCamera: Constants.arucoDetectionCamera,
    );
    var detectedAruco = collection.video.getArucoDetection(
      command.arucoId,
      desiredCamera: Constants.arucoDetectionCamera,
    );

    if (didSeeAruco && detectedAruco != null) {
      collection.logger.info("Found aruco");
      currentState = AutonomyState.APPROACHING;
      final arucoOrientation = Orientation(z: collection.imu.heading - detectedAruco.yaw);
      await collection.drive.faceOrientation(arucoOrientation);
      detectedAruco = await collection.video.waitForAruco(
        command.arucoId,
        desiredCamera: Constants.arucoDetectionCamera,
        timeout: const Duration(seconds: 3),
      );

      if (detectedAruco == null || !detectedAruco.hasBestPnpResult()) {
        // TODO: handle this condition properly
        collection.logger.error("Could not find desired Aruco tag");
        return;
      }

      collection.logger.debug(
        "Planning path to Aruco ID ${command.arucoId}",
        body: "Detection: ${detectedAruco.toProto3Json()}",
      );

      // In theory we could just find the relative position with the translation x and z,
      // however if the tag's rotation relative to itself is off (which can be common
      // when facing it head on), then it will be extremely innacurate. Since the SolvePnP's
      // distance is always extremely accurate, it is more reliable to use the distance
      // hypotenuse to the camera combined with trig of the tag's angle relative to the camera.
      final cameraToTag = detectedAruco.bestPnpResult.cameraToTarget;
      final distanceToTag = sqrt(
        pow(cameraToTag.translation.z, 2) + pow(cameraToTag.translation.x, 2),
      ) - 1; // don't drive *into* the tag

      if (distanceToTag < 1) {
        // well that was easy
        collection.drive.setLedStrip(ProtoColor.GREEN, blink: true);
        currentState = AutonomyState.AT_DESTINATION;
        return;
      }

      final relativeX = -distanceToTag * sin((collection.imu.heading - detectedAruco.yaw) * pi / 180);
      final relativeY = distanceToTag * cos((collection.imu.heading - detectedAruco.yaw) * pi / 180);

      final destinationCoordinates =
          (collection.gps.coordinates.asUtmCoordinates +
                  UTMCoordinates(y: relativeY, x: relativeX, zoneNumber: 1))
              .asGpsCoordinates;

      if (!await calculateAndFollowPath(
        destinationCoordinates,
        abortOnError: false,
        alternateEndCondition: () {
          detectedAruco = collection.video.getArucoDetection(
            command.arucoId,
            desiredCamera: Constants.arucoDetectionCamera,
          );
          if (detectedAruco == null) {
            return false;
          }
          final cameraToTag = detectedAruco!.bestPnpResult.cameraToTarget;
          final distanceToTag = sqrt(
            pow(cameraToTag.translation.z, 2) +
                pow(cameraToTag.translation.x, 2),
          );
          return distanceToTag < 1;
        },
      )) {
        collection.logger.error("Could not spin towards ArUco tag");
        currentCommand = null;
        return;
      }
      collection.logger.info("Arrived at estimated Aruco position");
      detectedAruco = collection.video.getArucoDetection(
        command.arucoId,
        desiredCamera: Constants.arucoDetectionCamera,
      );
      if (detectedAruco == null) {
        collection.logger.info("Re-spinning to find Aruco");
        await collection.drive.spinForAruco(
          command.arucoId,
          desiredCamera: Constants.arucoDetectionCamera,
        );
      }

      detectedAruco = collection.video.getArucoDetection(
        command.arucoId,
        desiredCamera: Constants.arucoDetectionCamera,
      );
      if (detectedAruco != null) {
        collection.logger.info("Rotating towards Aruco");
        await collection.drive.faceOrientation(
          Orientation(
            z: collection.imu.heading - detectedAruco!.yaw,
          ),
        );
      } else {
        collection.logger.warning("Could not find Aruco after following path");
      }

      collection.logger.info("Successfully reached within ${Constants.maxErrorMeters} meters of the Aruco tag");
      collection.drive.setLedStrip(ProtoColor.GREEN, blink: true);
      currentState = AutonomyState.AT_DESTINATION;
    }
    currentCommand = null;
  }

  @override
  Future<void> handleHammerTask(AutonomyCommand command) async {

  }

  @override
  Future<void> handleBottleTask(AutonomyCommand command) async {

  }
}
