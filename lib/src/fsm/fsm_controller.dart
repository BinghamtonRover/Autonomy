import "package:autonomy/src/fsm/rover_fsm.dart";

class FSMController {
  final List<StateInterface> _stateStack = [];

  void pushState(StateInterface state) {
    state.enter();
    _stateStack.add(state);
  }

  void transitionTo(StateInterface state) {
    _stateStack.removeLast().exit();
    state.enter();
    _stateStack.add(state);
  }

  void popState() {
    _stateStack.removeLast().exit();
  }

  void update() {
    if (_stateStack.isNotEmpty) {
      _stateStack.last.update();
    }
  }

  bool hasState() => _stateStack.isNotEmpty;

  bool hasSubstate() => _stateStack.length > 1;
}
