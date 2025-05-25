import "package:autonomy/src/fsm/rover_fsm.dart";

class TimeoutDecorator extends RoverState {
  final RoverState child;
  final Duration timeout;
  final StateCallback onTimeout;

  DateTime startTime = DateTime(0);

  TimeoutDecorator({
    required this.child,
    required this.timeout,
    required this.onTimeout,
  }) : super(child.controller);

  @override
  void enter() {
    startTime = DateTime.now();
    child.enter();
  }

  @override
  void update() {
    if (DateTime.now().difference(startTime) > timeout) {
      return onTimeout(controller);
    }
    child.update();
  }

  @override
  void exit() {
    child.exit();
  }
}
