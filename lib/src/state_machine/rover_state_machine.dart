import "package:autonomy/src/state_machine/state_controller.dart";

export "state_controller.dart";
export "rover_state.dart";
export "decorators.dart";
export "state_utils.dart";

/// Callback for a state method that takes in a controller
typedef StateCallback = void Function(StateController controller);
