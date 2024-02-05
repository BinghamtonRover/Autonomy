import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";
import "package:meta/meta.dart";

abstract class OrchestratorInterface extends Service {
  final AutonomyInterface collection;
  OrchestratorInterface({required this.collection});

  AutonomyCommand? currentCommand;
  void onCommand(AutonomyCommand command) {
    currentCommand = command;
    switch (command.task) {
      case AutonomyTask.GPS_ONLY: handleGpsTask(command);
      case AutonomyTask.VISUAL_MARKER: handleArucoTask(command);
      // TODO: Add more tasks 
      default: collection.logger.error("Unrecognized task: ${command.task}");  // ignore: no_default_cases
    }
  }

  @mustCallSuper
  Future<void> abort() async {
    currentCommand = null;
    collection.logger.warning("Aborting task!");
    await collection.drive.stop();
  }
  
  Future<void> handleGpsTask(AutonomyCommand command);
  Future<void> handleArucoTask(AutonomyCommand command);
  Future<void> handleHammerTask(AutonomyCommand command);
  Future<void> handleBottleTask(AutonomyCommand command);
}
