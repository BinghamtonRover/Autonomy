import "package:autonomy/src/fsm/rover_fsm.dart";

abstract class StateInterface {
  FSMController get controller;

  void enter();
  void update();
  void exit();
}

class RoverState implements StateInterface {
  @override
  final FSMController controller;

  RoverState(this.controller);

  @override
  void enter() {}

  @override
  void update() {}

  @override
  void exit() {}
}
