import "dart:io";

import "package:autonomy/interfaces.dart";
import "package:burt_network/burt_network.dart";
import "package:meta/meta.dart";

abstract class OrchestratorInterface extends Service {
  final AutonomyInterface collection;
  OrchestratorInterface({required this.collection});

  AutonomyCommand? currentCommand;
  AutonomyState currentState = AutonomyState.AUTONOMY_STATE_UNDEFINED;
  Future<void> onCommand(AutonomyCommand command) async {
    collection.server.sendMessage(command);
    if (command.abort) return abort();
    if (currentCommand != null) {
      collection.logger.error("Already executing a command", body: "Abort first if you want to switch tasks");
      return;
    }

    if (!collection.hasValue) {
      // We don't wait here because this was explicitly requested by the operator.
      // Users expect immediate feedback, so we give an error instead of freezing.
      collection.logger.error("Sensors haven't gotten any readings yet!");
      currentState = AutonomyState.NO_SOLUTION;
      return;
    }
    await collection.drive.resolveOrientation();
    currentCommand = command;
    switch (command.task) {
      case AutonomyTask.GPS_ONLY: await handleGpsTask(command);
      case AutonomyTask.VISUAL_MARKER: await handleArucoTask(command);
      // TODO: Add more tasks
      default: collection.logger.error("Unrecognized task: ${command.task}");  // ignore: no_default_cases
    }
  }

  @override
  Future<bool> init() async {
    collection.server.messages.onMessage(
      name: AutonomyCommand().messageName,
      constructor: AutonomyCommand.fromBuffer,
      callback: onCommand,
    );
    return true;
  }

  @mustCallSuper
  Future<void> abort() async {
    currentCommand = null;
    collection.logger.warning("Aborting task!");
    currentState = AutonomyState.ABORTING;
    await collection.drive.stop();
    await collection.dispose();
    exit(1);
  }

  Future<void> handleGpsTask(AutonomyCommand command);
  Future<void> handleArucoTask(AutonomyCommand command);
  Future<void> handleHammerTask(AutonomyCommand command);
  Future<void> handleBottleTask(AutonomyCommand command);
  AutonomyData get statusMessage;
}