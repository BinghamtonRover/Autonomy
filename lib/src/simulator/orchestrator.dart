import "dart:io";

import "package:autonomy/interfaces.dart";
import "package:burt_network/generated.dart";

class OrchestratorSimulator extends OrchestratorInterface {
  OrchestratorSimulator({required super.collection});
  
  @override
  Future<void> abort() async {
    await super.abort();
    await collection.dispose();
    exit(1);
  }

  @override
  Future<void> handleGpsTask(AutonomyCommand command) async {

  }

  @override
  Future<void> handleArucoTask(AutonomyCommand command) async {

  }

  @override
  Future<void> handleHammerTask(AutonomyCommand command) async {

  }

  @override
  Future<void> handleBottleTask(AutonomyCommand command) async {

  }
}
