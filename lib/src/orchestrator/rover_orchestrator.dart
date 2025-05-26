import "dart:math";

import "package:autonomy/constants.dart";
import "package:autonomy/interfaces.dart";
import "package:autonomy/src/fsm/rover_fsm.dart";
import "package:autonomy/src/utils/behavior_util.dart";
import "package:behavior_tree/behavior_tree.dart";
import "dart:async";

import "package:coordinate_converter/coordinate_converter.dart";

/// State for when the rover is finding a path
///
/// When ran the state will attempt to plan a path to its given [destination],
/// if successful, it will transition to [NavigationState], if unsuccessful,
/// it will be popped from the stack.
class PathingState extends RoverState {
  /// The autonomy collection for the state
  final AutonomyInterface collection;

  /// The orchestrator for the state
  final RoverOrchestrator orchestrator;

  /// The destination to plan a path to
  final GpsCoordinates destination;

  /// Default constructor for [PathingState]
  PathingState(
    super.controller, {
    required this.collection,
    required this.orchestrator,
    required this.destination,
  });

  @override
  void enter() {
    orchestrator.currentState = AutonomyState.PATHING;
    orchestrator.findAndLockObstacles();
  }

  @override
  void update() {
    final current = collection.gps.coordinates;
    orchestrator.currentPath = collection.pathfinder.getPath(
      orchestrator.currentCommand!.destination,
    );
    if (orchestrator.currentPath == null) {
      collection.logger.error(
        "Could not find a path",
        body:
            "No path found from ${current.prettyPrint()} to ${destination.prettyPrint()}",
      );
      controller.popState();
    } else {
      collection.logger.debug(
        "Found a path from ${current.prettyPrint()} to ${destination.prettyPrint()}: ${orchestrator.currentPath!.length} steps",
      );
      collection.logger.debug("Here is a summary of the path");
      for (final step in orchestrator.currentPath!) {
        collection.logger.debug(step.toString());
      }
      controller.transitionTo(
        NavigationState(
          controller,
          collection: collection,
          orchestrator: orchestrator,
          destination: destination,
        ),
      );
    }
  }
}

/// State to manage the navigation of the rover
///
/// This state should be pushed after [PathingState], as it depends
/// on having a path already made for the rover to follow.
///
/// This state will manage following each individual step of the path as well
/// as performing necessary corrections and replanning.
///
/// When the path has to be replanned, this state will transition to [PathingState]
class NavigationState extends RoverState {
  /// The collection for the state
  final AutonomyInterface collection;

  /// The orchestrator for the state
  final RoverOrchestrator orchestrator;

  /// The final destination to navigate to
  final GpsCoordinates destination;

  /// Whether or not the state has performed pre-step correction
  bool hasCorrected = false;

  /// Whether or not the state has just completed following a path step
  bool hasFollowed = false;

  /// The index of the waypoint being followed
  int waypointIndex = 0;

  /// The current step of the path being followed
  AutonomyAStarState? currentPathState;

  /// Default constructor for [NavigationState]
  NavigationState(
    super.controller, {
    required this.collection,
    required this.orchestrator,
    required this.destination,
  });

  @override
  void enter() {
    waypointIndex = 0;
    hasCorrected = false;
    hasFollowed = false;

    currentPathState = orchestrator.currentPath?[waypointIndex];
    orchestrator.currentState = AutonomyState.DRIVING;
  }

  /// Checks if the rover is oriented properly before driving the [state]
  ///
  /// This is assuming that the step's instruction is to drive forward.
  ///
  /// If the rover is not facing the proper direction, a new state will be pushed
  /// to re-correct the rover's orientation
  bool checkOrientation(AutonomyAStarState state) {
    Orientation targetOrientation;
    // if it has RTK, point towards the next coordinate
    if (collection.gps.coordinates.hasRTK) {
      final difference =
          state.position.toUTM() - collection.gps.coordinates.toUTM();

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
      controller.pushState(
        collection.drive.faceOrientationState(targetOrientation),
      );
      return true;
    }
    return false;
  }

  /// Checks if the rover is within a certain distance of [state]'s starting position
  ///
  /// If the rover is not within [Constants.replanErrorMeters] of the state's starting
  /// position, the path will be replanned
  bool checkPosition(AutonomyAStarState state) {
    final distanceError = collection.gps.coordinates.distanceTo(
      state.startPostition,
    );
    if (distanceError > Constants.replanErrorMeters) {
      collection.logger.info(
        "Replanning Path",
        body: "Rover is $distanceError meters off the path",
      );
      controller.transitionTo(
        PathingState(
          controller,
          collection: collection,
          orchestrator: orchestrator,
          destination: destination,
        ),
      );
    }
    return true;
  }

  /// Check's the position and orientation of [state] before following it
  ///
  /// If the instruction of [state] is to move forward, it will check if the
  /// orientation is correct using [checkOrientation], otherwise, it will check
  /// the position using [checkPosition]
  bool checkCurrentPosition(AutonomyAStarState state) {
    if (state.instruction == DriveDirection.forward) {
      return checkOrientation(state);;
    } else {
      return checkPosition(state);
    }
  }

  @override
  void update() {
    if (currentPathState == null) {
      controller.popState();
      return;
    }
    if (!hasCorrected) {
      hasCorrected = true;
      if(checkCurrentPosition(currentPathState!)) return;

    }
    if (!hasFollowed) {
      hasFollowed = true;
      collection.logger.debug(currentPathState!.toString());
      controller.pushState(collection.drive.driveStateState(currentPathState!));
      return;
    }
    if (waypointIndex >= 5 || orchestrator.findAndLockObstacles()) {
      collection.drive.stop();
      controller.transitionTo(
        PathingState(
          controller,
          collection: collection,
          orchestrator: orchestrator,
          destination: destination,
        ),
      );
      return;
    }
    if (collection.gps.isNear(destination, Constants.maxErrorMeters)) {
      controller.popState();
      return;
    }

    orchestrator.traversed.add(currentPathState!.position);

    waypointIndex++;
    hasCorrected = false;
    hasFollowed = false;
    currentPathState = orchestrator.currentPath?[waypointIndex];
  }
}

class RoverOrchestrator extends OrchestratorInterface with ValueReporter {
  /// The GPS coordinates that the rover has traversed during the task
  final List<GpsCoordinates> traversed = [];

  /// The current path that the rover is following
  List<AutonomyAStarState>? currentPath;

  /// Whether or not the rover should replan the path, this is managed by the behavior tree
  bool replanPath = true;

  /// The current waypoint index of the path that the rover is following
  int waypointIndex = 0;

  /// Whether or not the rover has checked the waypoint orientation of the current path step
  bool hasCheckedWaypointOrientation = false;

  /// Whether or not the rover is currently correction waypoint orientation
  bool isCorrectingWaypointOrientation = false;

  /// Whether or not the rover has checked the waypoint error for the current step in the path
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
  void onCommandEnd() {
    currentPath = null;
    super.onCommandEnd();
  }

  @override
  AutonomyData get statusMessage => AutonomyData(
    destination: currentCommand?.destination,
    state: currentState,
    obstacles: [
      ...collection.pathfinder.obstacles,
      ...collection.pathfinder.lockedObstacles,
    ],
    path: {
      for (final transition in currentPath ?? <AutonomyAStarState>[])
        transition.position,
      ...traversed,
    },
    task: currentCommand?.task,
    crash: false, // TODO: Investigate if this is used and how to use it better
  );

  @override
  Message getMessage() => statusMessage;

  /// Finds new obstacles and locks them if any intersect with the current path
  ///
  /// If the implementation of the obstacle detector has detected any obstacles,
  /// it will "lock" any obstacles that intersect with the current path, to prevent
  /// future paths from being planned in that area.
  bool findAndLockObstacles() {
    if (!collection.detector.findObstacles()) {
      return false;
    }

    if (currentPath == null) return true;

    final toLock = <GpsCoordinates>{};

    for (final step in currentPath!.map((state) => state.position)) {
      // Since we're iterating over the obstacles that we also want to lock,
      // we have to create a copy of the ones we want to lock, otherwise we'll
      // be modifying the array while iterating over it
      toLock.addAll(
        collection.pathfinder.obstacles.where(
          (obstacle) => collection.pathfinder.isObstacle(step),
        ),
      );
    }

    toLock.forEach(collection.pathfinder.lockObstacle);

    return true;
  }

  /// A node that will trigger a path replan when [condition] is true
  ///
  /// If [condition] is true, [replanPath] will be set to true, and the
  /// node will fail. Otherwise, it will be successful.
  BaseNode replanOnCondition(bool Function() condition) => Task(() {
    if (condition()) {
      replanPath = true;
      return NodeStatus.failure;
    }
    return NodeStatus.success;
  });

  /// A node to plan a path towards [destination]
  ///
  /// This node will only create a new path towards [destination], and not follow it.
  ///
  /// This node will fail if either:
  /// 1. There is a current path already planned
  /// 2. There is no command currently running
  /// 3. The GPS hasn't received a value
  /// 4. The IMU hasn't received a value
  /// 5. A path could not be planned
  /// Otherwise, this node will be successful
  ///
  /// Since this node will fail if a path is already planned,
  /// this should be wrapped in a decorator such as a selector
  /// to prevent the entire tree from failing.
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
          isCorrectingWaypointOrientation = false;
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

  /// Creates a node to follow a path towards [destination]
  ///
  /// This node will handle the logic of driving through the individual steps
  /// of [currentPath], handling obstacle detection, replanning logic, and recorrection.
  ///
  /// This node will not plan a new path, see [planPath]
  ///
  /// This node will fail if either:
  /// 1. There is no path planned
  /// 2. The node for following the current path step failed
  /// 3. A new obstacle was detected
  /// 4. 5 steps of the path have been followed
  /// 5. A step of the path was completed but the rover has not reached [destination]
  ///
  /// Since this node will fail if the rover isn't near [destination], this
  /// should be wrapped in a decorator such as a selector or inverter to prevent
  /// the entire tree from failing.
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

          if (!hasCheckedWaypointOrientation &&
              !isCorrectingWaypointOrientation) {
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
              if (isCorrectingWaypointOrientation) {
                return true;
              }
              if (!hasCheckedWaypointOrientation) {
                return currentWaypoint.instruction == DriveDirection.forward &&
                    (collection.imu.heading - targetOrientation.z)
                            .clampHalfAngle()
                            .abs() >=
                        Constants.driveRealignmentEpsilon;
              }
              return false;
            }).inverted,

            // If the previous one fails, then it has to recorrect, run a
            // task to set the state of recorrecting, this is inverted so
            // it will continue with the selection
            Task(() {
              isCorrectingWaypointOrientation = true;
              return NodeStatus.success;
            }).inverted,

            // Face the desired orientation
            SuppliedNode(
              key: () => targetOrientation,
              () => collection.drive.faceOrientationNode(targetOrientation),
            ),
          ],
        ),

        // If it makes it through here, it either has corrected, or doesn't need to correct.
        // Either way, assume that it has corrected its orientation
        Task(() {
          hasCheckedWaypointOrientation = true;
          isCorrectingWaypointOrientation = false;
          return NodeStatus.success;
        }),

        // If the distance to the start of our waypoint is too large, replan
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

        // If the waypoint state has been driven, increase our waypoint index,
        // and reset our correction state
        Task(() {
          traversed.add(currentWaypoint.position);
          waypointIndex++;
          hasCheckedWaypointOrientation = false;
          isCorrectingWaypointOrientation = false;
          hasCheckedWaypointError = false;
          return NodeStatus.success;
        }),

        // Replan if there are new obstacles or we've traversed 5 waypoints,
        // we want to periodically replan the path to ensure we're on track
        replanOnCondition(() => findAndLockObstacles() || waypointIndex >= 5),

        // This technically isn't needed for following the path, however, the tree root
        // relies on the tree not being "success" until we have reached our destination,
        // adding this here guarantees that this node will only be successful if we are
        // done following
        Condition(
          () => collection.gps.isNear(destination, Constants.maxErrorMeters),
        ),
      ],
    );
  }

  /// Creates a node to plan and follow a path towards [destination]
  ///
  /// This node combines [planPath] and [followPath] to dynamically plan
  /// and follow a path to drive the rover towards [destination].
  ///
  /// If a path could not be planned towards [destination], the node will
  /// fail. If the rover has reached [destination], it will succeed, otherwise,
  /// it will return running.
  BaseNode pathToDestination(GpsCoordinates destination) {
    var resolvedOrientation = false;
    return Sequence(
      children: [
        // If we haven't initially resolved our orientation, resolve the orientation
        Selector(
          children: [
            Condition(() => resolvedOrientation),
            SuppliedNode(() => collection.drive.resolveOrientationNode()),
          ],
        ),
        Task(() {
          resolvedOrientation = true;
          return NodeStatus.success;
        }),
        Selector(
          children: [
            // Success if we are near the destination
            Condition(
              () =>
                  collection.gps.isNear(destination, Constants.maxErrorMeters),
            ),

            // Plan the path, if there is already a path,
            // this will fail and the selection will continue
            planPath(destination),

            // Follow the path, this will fail if it hasn't reached the destination,
            // this failure scenario is "caught" in the next step
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
    while (!collection.gps.coordinates.isNear(goal) &&
        !(alternateEndCondition?.call() ?? false)) {
      // Calculate a path
      collection.logger.debug("Finding a path");
      currentState = AutonomyState.PATHING;
      final path = collection.pathfinder.getPath(goal);
      currentPath = path; // also use local variable path for promotion
      if (path == null) {
        final current = collection.gps.coordinates;
        collection.logger.error(
          "Could not find a path",
          body:
              "No path found from ${current.prettyPrint()} to ${goal.prettyPrint()}",
        );
        if (abortOnError) {
          currentState = AutonomyState.NO_SOLUTION;
          currentCommand = null;
        }
        return false;
      }
      // Try to take that path
      final current = collection.gps.coordinates;
      collection.logger.debug(
        "Found a path from ${current.prettyPrint()} to ${goal.prettyPrint()}: ${path.length} steps",
      );
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
        final distanceError = collection.gps.coordinates.distanceTo(
          state.startPostition,
        );
        if (distanceError >= Constants.replanErrorMeters) {
          collection.logger.info(
            "Replanning Path",
            body: "Rover is $distanceError meters off the path",
          );
          findAndLockObstacles();
          break;
        }
        // Re-align to desired start orientation if angle is too far
        if (state.instruction == DriveDirection.forward) {
          Orientation targetOrientation;
          // if it has RTK, point towards the next coordinate
          if (collection.gps.coordinates.hasRTK) {
            final difference =
                state.position.toUTM() - collection.gps.coordinates.toUTM();

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
          break; // calculate a new path
        }
      }
    }
    return true;
  }

  @override
  void handleGpsTask(AutonomyCommand command) {
    final destination = command.destination;
    collection.logger.info(
      "Received GPS Task",
      body: "Go to ${destination.prettyPrint()}",
    );
    collection.logger.debug(
      "Currently at ${collection.gps.coordinates.prettyPrint()}",
    );
    traversed.clear();
    collection.drive.setLedStrip(ProtoColor.RED);
    waypointIndex = 0;
    hasCheckedWaypointError = false;
    hasCheckedWaypointOrientation = false;
    isCorrectingWaypointOrientation = false;
    replanPath = true;
    behaviorRoot = pathToDestination(destination);
    controller.pushState(
      SequenceState(
        controller,
        steps: [
          collection.drive.resolveOrientationState(),
          PathingState(
            controller,
            collection: collection,
            orchestrator: this,
            destination: destination,
          ),
        ],
      ),
    );
    executionTimer = PeriodicTimer(const Duration(milliseconds: 10), (timer) {
      if (currentCommand == null) {
        collection.logger.warning(
          "Execution timer running while command is null",
          body: "Canceling timer",
        );
        onCommandEnd();
        timer.cancel();
        return;
      }
      if (!controller.hasState()) {
        currentState = AutonomyState.NO_SOLUTION;
        onCommandEnd();
        timer.cancel();
        return;
      }
      if (collection.gps.isNear(destination, Constants.maxErrorMeters)) {
        timer.cancel();
        collection.logger.info("Task complete");
        onCommandEnd();
        currentState = AutonomyState.AT_DESTINATION;
        collection.drive.setLedStrip(ProtoColor.GREEN, blink: true);
        return;
      }
      controller.update();
      // behaviorRoot.tick();
      // if (behaviorRoot.status == NodeStatus.failure) {
      //   behaviorRoot.reset();
      //   currentState = AutonomyState.NO_SOLUTION;
      //   currentCommand = null;
      //   timer.cancel();
      // } else if (behaviorRoot.status == NodeStatus.success) {
      //   behaviorRoot.reset();
      //   timer.cancel();
      //   collection.logger.info("Task complete");
      //   currentState = AutonomyState.AT_DESTINATION;
      //   collection.drive.setLedStrip(ProtoColor.GREEN, blink: true);
      //   currentCommand = null;
      // }
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
  Future<void> handleArucoTask(AutonomyCommand command) async {
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
      if (!await calculateAndFollowPath(
        command.destination,
        abortOnError: false,
      )) {
        collection.logger.error(
          "Failed to follow path towards initial destination",
        );
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
      collection.logger.error(
        "Could not find desired Aruco tag after rotating towards it",
      );
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
        ) -
        1; // don't drive *into* the tag

    if (distanceToTag < 1) {
      // well that was easy
      collection.drive.setLedStrip(ProtoColor.GREEN, blink: true);
      currentState = AutonomyState.AT_DESTINATION;
      currentCommand = null;
      return;
    }

    final relativeX =
        -distanceToTag *
        sin((collection.imu.heading - detectedAruco!.yaw) * pi / 180);
    final relativeY =
        distanceToTag *
        cos((collection.imu.heading - detectedAruco!.yaw) * pi / 180);

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
  Future<void> handleHammerTask(AutonomyCommand command) async {}

  @override
  Future<void> handleBottleTask(AutonomyCommand command) async {}
}
