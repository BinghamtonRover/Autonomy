import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

abstract class OrchestratorInterface implements Service {
  final AutonomyInterface collection;
  OrchestratorInterface({required this.collection});

  AutonomyCommand? currentCommand;
  void onCommand(AutonomyCommand command);
  void stop();
}
