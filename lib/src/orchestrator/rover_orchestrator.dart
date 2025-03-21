import "dart:math";

import "package:autonomy/constants.dart";
import "package:autonomy/interfaces.dart";
import "package:autonomy/src/utils/behavior_util.dart";
import "package:behavior_tree/behavior_tree.dart";
import "dart:async";

import "package:coordinate_converter/coordinate_converter.dart";

class RoverOrchestrator extends OrchestratorInterface with ValueReporter {
  final List<GpsCoordinates> traversed = [];
  List<AutonomyAStarState>? currentPath;

  bool replanPath = true;
  int waypointIndex = 0;
  bool hasCheckedWaypointOrientation = false;
  bool hasCheckedWaypointError = false;

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
  Future<void> abort() async {
    currentPath = null;
    return super.abort();
  }

  @override
  AutonomyData get statusMessage => AutonomyData(
    destination: currentCommand?.destination,
    state: currentState,
    obstacles: [
      ...collection.pathfinder.obstacles,
      ...collection.pathfinder.lockedObstacles,
    ],
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

  BaseNode replanOnCondition(bool Function() condition) => Task(() {
    if (condition()) {
      replanPath = true;
      return NodeStatus.failure;
    }
    return NodeStatus.success;
  });

  BaseNode planPath(GpsCoordinates destination) => Sequence(
    children: [
      Condition(
        () =>
            replanPath &&
            currentCommand != null &&
            collection.gps.hasValue &&
            collection.imu.hasValue,
      ),
      Task(() {
        collection.logger.debug("Finding any new obstacles");
        findAndLockObstacles();
        return NodeStatus.success;
      }),
      Task(() {
        collection.logger.debug("Finding a path");
        currentState = AutonomyState.PATHING;
        replanPath = false;
        return NodeStatus.success;
      }),
      Condition(() {
        if (currentCommand == null) {
          return false;
        }
        final current = collection.gps.coordinates;
        currentPath = collection.pathfinder.getPath(
          currentCommand!.destination,
        );
        if (currentPath == null) {
          collection.logger.error(
            "Could not find a path",
            body:
                "No path found from ${current.prettyPrint()} to ${destination.prettyPrint()}",
          );
        } else {
          waypointIndex = 0;
          hasCheckedWaypointError = false;
          hasCheckedWaypointOrientation = false;
          collection.logger.debug(
            "Found a path from ${current.prettyPrint()} to ${destination.prettyPrint()}: ${currentPath!.length} steps",
          );
          collection.logger.debug("Here is a summary of the path");
          for (final step in currentPath!) {
            collection.logger.debug(step.toString());
          }
        }
        return currentPath != null;
      }),
    ],
  );

  BaseNode followPath(GpsCoordinates destination) {
    late AutonomyAStarState currentWaypoint;
    // Orientation the rover should be facing before driving forward
    var targetOrientation = collection.imu.nearest.orientation;

    return Sequence(
      children: [
        Task(() {
          if (currentPath == null) {
            return NodeStatus.failure;
          }
          if (waypointIndex >= currentPath!.length) {
            return NodeStatus.failure;
          }
          currentWaypoint = currentPath![waypointIndex];
          currentState = AutonomyState.DRIVING;

          if (!hasCheckedWaypointOrientation) {
            // if it has RTK, point towards the next coordinate
            if (collection.gps.coordinates.hasRTK) {
              final difference =
                  currentWaypoint.position.toUTM() -
                  collection.gps.coordinates.toUTM();

              final angle = atan2(difference.y, difference.x) * 180 / pi;

              targetOrientation = Orientation(z: angle);
            } else {
              targetOrientation = currentWaypoint.orientation.orientation;
            }
          }

          return NodeStatus.success;
        }),
        Selector(
          children: [
            Condition(() {
              if (!hasCheckedWaypointOrientation) {
                hasCheckedWaypointOrientation = true;
                return currentWaypoint.instruction == DriveDirection.forward &&
                    (collection.imu.heading - targetOrientation.z)
                            .clampHalfAngle()
                            .abs() >=
                        Constants.driveRealignmentEpsilon;
              }
              return false;
            }).inverted,
            SuppliedNode(
              key: () => targetOrientation,
              () => collection.drive.faceOrientationNode(targetOrientation),
            ),
          ],
        ),
        replanOnCondition(() {
          if (!hasCheckedWaypointError) {
            hasCheckedWaypointError = true;
            return collection.gps.coordinates.distanceTo(
                  currentWaypoint.startPostition,
                ) >=
                Constants.replanErrorMeters;
          }
          return false;
        }),
        // ConditionalNode(
        //   condition: () {
        //     if (currentWaypoint.instruction != DriveDirection.forward) {
        //       return false;
        //     }
        //     return (collection.imu.heading - targetOrientation.z)
        //             .clampHalfAngle() >
        //         Constants.driveRealignmentEpsilon;
        //   },
        //   onTrue: SuppliedNode(
        //     key: () => targetOrientation,
        //     () => collection.drive.faceOrientationNode(targetOrientation),
        //   ),
        // ),
        SuppliedNode(
          key: () => waypointIndex,
          () => collection.drive.driveStateNode(currentWaypoint),
        ),
        Task(() {
          traversed.add(currentWaypoint.position);
          waypointIndex++;
          hasCheckedWaypointOrientation = false;
          hasCheckedWaypointError = false;
          return NodeStatus.success;
        }),
        replanOnCondition(() => findAndLockObstacles() || waypointIndex >= 5),
        Condition(() => collection.gps.isNear(destination, Constants.maxErrorMeters)),
      ],
    );
  }

  BaseNode pathToDestination(GpsCoordinates destination) {
    var resolvedOrientation = false;
    return Sequence(
      children: [
        Selector(
          children: [
            Condition(() {
              if (!resolvedOrientation) {
                resolvedOrientation = true;
                return true;
              }
              return false;
            }).inverted,
            SuppliedNode(() => collection.drive.resolveOrientationNode()),
          ],
        ),
        Selector(
          children: [
            Condition(
              () =>
                  collection.gps.isNear(destination, Constants.maxErrorMeters),
            ),
            planPath(destination),
            followPath(destination),
            // Only runs if plan path failed, and follow path failed, indicating 2 scenarios:
            // 1. Couldn't find a path at all
            // 2. Couldn't follow a specific step of the path
            Task(() {
              // Failed to find a path (Scenario 1)
              if (!replanPath && currentPath == null) {
                return NodeStatus.failure;
              } else {
                // Either a timeout or new obstacle was found, replan path and continue (Scenario 2)
                return NodeStatus.running;
              }
            }),
          ],
        ),
        Task(() {
          if (collection.gps.isNear(destination, Constants.maxErrorMeters)) {
            return NodeStatus.success;
          }
          return NodeStatus.running;
        }),
      ],
    );
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
            final difference = state.position.toUTM() - collection.gps.coordinates.toUTM();

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
  void handleGpsTask(AutonomyCommand command) {
    final destination = command.destination;
    collection.logger.info("Received GPS Task", body: "Go to ${destination.prettyPrint()}");
    collection.logger.debug("Currently at ${collection.gps.coordinates.prettyPrint()}");
    traversed.clear();
    collection.drive.setLedStrip(ProtoColor.RED);
    waypointIndex = 0;
    hasCheckedWaypointError = false;
    hasCheckedWaypointOrientation = false;
    replanPath = true;
    behaviorRoot = pathToDestination(destination);
    behaviorTreeTimer = Timer.periodic(const Duration(milliseconds: 10), (
      timer,
    ) {
      if (currentCommand == null) {
        return;
      }
      behaviorRoot.tick();
      if (behaviorRoot.status == NodeStatus.failure) {
        behaviorRoot.reset();
        currentState = AutonomyState.NO_SOLUTION;
        currentCommand = null;
        timer.cancel();
      } else if (behaviorRoot.status == NodeStatus.success) {
        behaviorRoot.reset();
        timer.cancel();
        collection.logger.info("Task complete");
        currentState = AutonomyState.AT_DESTINATION;
        collection.drive.setLedStrip(ProtoColor.GREEN, blink: true);
        currentCommand = null;
      }
    });
    // detect obstacles before and after resolving orientation, as a "scan"
    // collection.detector.findObstacles();
    // await collection.drive.resolveOrientation();
    // collection.detector.findObstacles();

    // if (!await calculateAndFollowPath(command.destination)) {
    //   return;
    // }
  }

  @override
  void handleArucoTask(AutonomyCommand command) async {
    collection.drive.setLedStrip(ProtoColor.RED);

    // Go to GPS coordinates
    collection.logger.info("Got ArUco Task");

    DetectedObject? detectedAruco;

    behaviorRoot = Sequence(
      children: [
        // Go to initial coordinates given
        Selector(
          children: [
            Condition(
              () =>
                  command.destination !=
                  GpsCoordinates(latitude: 0, longitude: 0),
            ).inverted,
            pathToDestination(command.destination),
            // If failed to reach
            Task(() {
              collection.logger.error(
                "Failed to follow path towards initial destination",
              );
              currentState = AutonomyState.NO_SOLUTION;
              currentCommand = null;
              return NodeStatus.failure;
            }),
          ],
        ),
        Task(() {
          currentState = AutonomyState.SEARCHING;
          collection.logger.info("Searching for ArUco tag");
          return NodeStatus.success;
        }),
        // Try to spin and find a tag
        Selector(
          children: [
            collection.drive.spinForArucoNode(
              command.arucoId,
              desiredCamera: Constants.arucoDetectionCamera,
            ),
            Task(() {
              collection.logger.error("Could not find desired Aruco tag");
              currentState = AutonomyState.NO_SOLUTION;
              currentCommand = null;
              return NodeStatus.failure;
            }),
          ],
        ),
        Condition(() {
          detectedAruco = collection.video.getArucoDetection(
            command.arucoId,
            desiredCamera: Constants.arucoDetectionCamera,
          );
          return detectedAruco != null;
        }),
        // Face towards aruco tag
        SuppliedNode(
          () => collection.drive.faceOrientationNode(
            Orientation(z: collection.imu.heading - detectedAruco!.yaw),
          ),
        ),
        Selector(
          children: [
            Condition(
              () =>
                  collection.video.getArucoDetection(
                    command.arucoId,
                    desiredCamera: Constants.arucoDetectionCamera,
                  ) !=
                  null,
            ),
            Task(() => NodeStatus.running),
          ],
        ).withTimeout(const Duration(seconds: 3)),
      ],
    );

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
    detectedAruco = collection.video.getArucoDetection(
      command.arucoId,
      desiredCamera: Constants.arucoDetectionCamera,
    );

    if (!didSeeAruco || detectedAruco == null) {
      collection.logger.error("Could not find desired Aruco tag");
      currentState = AutonomyState.NO_SOLUTION;
      currentCommand = null;
      return;
    }

    collection.logger.info("Found aruco");
    currentState = AutonomyState.APPROACHING;
    final arucoOrientation = Orientation(
      z: collection.imu.heading - detectedAruco!.yaw,
    );
    await collection.drive.faceOrientation(arucoOrientation);
    detectedAruco = await collection.video.waitForAruco(
      command.arucoId,
      desiredCamera: Constants.arucoDetectionCamera,
      timeout: const Duration(seconds: 3),
    );

    if (detectedAruco == null || !detectedAruco!.hasBestPnpResult()) {
      // TODO: handle this condition properly
      collection.logger.error("Could not find desired Aruco tag after rotating towards it");
      currentState = AutonomyState.NO_SOLUTION;
      currentCommand = null;
      return;
    }

    collection.logger.debug(
      "Planning path to Aruco ID ${command.arucoId}",
      body: "Detection: ${detectedAruco!.toProto3Json()}",
    );

    // In theory we could just find the relative position with the translation x and z,
    // however if the tag's rotation relative to itself is off (which can be common
    // when facing it head on), then it will be extremely innacurate. Since the SolvePnP's
    // distance is always extremely accurate, it is more reliable to use the distance
    // hypotenuse to the camera combined with trig of the tag's angle relative to the camera.
    final cameraToTag = detectedAruco!.bestPnpResult.cameraToTarget;
    final distanceToTag =
        sqrt(
          pow(cameraToTag.translation.z, 2) + pow(cameraToTag.translation.x, 2),
        ) - 1; // don't drive *into* the tag

    if (distanceToTag < 1) {
      // well that was easy
      collection.drive.setLedStrip(ProtoColor.GREEN, blink: true);
      currentState = AutonomyState.AT_DESTINATION;
      currentCommand = null;
      return;
    }

    final relativeX = -distanceToTag * sin((collection.imu.heading - detectedAruco!.yaw) * pi / 180);
    final relativeY = distanceToTag * cos((collection.imu.heading - detectedAruco!.yaw) * pi / 180);

    final destinationCoordinates =
        (collection.gps.coordinates.toUTM() +
                UTMCoordinates(y: relativeY, x: relativeX, zoneNumber: 1))
            .toGps();

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
          pow(cameraToTag.translation.z, 2) + pow(cameraToTag.translation.x, 2),
        );
        return distanceToTag < 1;
      },
    )) {
      collection.logger.error("Could not spin towards ArUco tag");
      currentState = AutonomyState.NO_SOLUTION;
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
        Orientation(z: collection.imu.heading - detectedAruco!.yaw),
      );
    } else {
      collection.logger.warning("Could not find Aruco after following path");
    }

    collection.logger.info(
      "Successfully reached within ${Constants.maxErrorMeters} meters of the Aruco tag",
    );
    collection.drive.setLedStrip(ProtoColor.GREEN, blink: true);
    currentState = AutonomyState.AT_DESTINATION;

    currentCommand = null;
  }

  @override
  void handleHammerTask(AutonomyCommand command) async {

  }

  @override
  void handleBottleTask(AutonomyCommand command) async {

  }
}
