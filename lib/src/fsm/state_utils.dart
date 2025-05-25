import "package:autonomy/src/fsm/rover_fsm.dart";

class DelayedState extends RoverState {
  final Duration delayTime;

  DateTime _startTime = DateTime(0);

  DelayedState(super.controller, {required this.delayTime});

  @override
  void enter() {
    _startTime = DateTime.now();
  }

  @override
  void update() {
    if (DateTime.now().difference(_startTime) >= delayTime) {
      controller.popState();
    }
  }
}

class FunctionalState extends RoverState {
  final StateCallback? onEnter;
  final StateCallback? onUpdate;
  final StateCallback? onExit;

  FunctionalState(
    super.controller, {
    this.onEnter,
    this.onUpdate,
    this.onExit,
  });

  @override
  void enter() => onEnter?.call(controller);

  @override
  void update() => onUpdate?.call(controller);

  @override
  void exit() => onExit?.call(controller);
}

class SequenceState extends RoverState {
  final List<StateInterface> steps;

  int _stepIndex = 0;

  SequenceState(super.controller, {required this.steps});

  @override
  void enter() {
    if (steps.isNotEmpty) {
      controller.pushState(steps[_stepIndex]);
    }
  }

  @override
  void update() {
    _stepIndex++;
    // There's another state left in the sequence, push it
    if (_stepIndex < steps.length) {
      controller.pushState(steps[_stepIndex]);
    } else {
      // sequence is done
      controller.popState();
    }
  }
}
