import "package:autonomy/src/fsm/fsm_controller.dart";

export "fsm_controller.dart";
export "rover_state.dart";
export "decorators.dart";
export "state_utils.dart";

/// Callback for a state method that takes in a controller
typedef StateCallback = void Function(FSMController controller);
