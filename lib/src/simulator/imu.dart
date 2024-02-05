import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

class ImuSimulator extends ImuInterface with ValueReporter {  
  ImuSimulator({required super.collection});
  
  @override
  RoverPosition getMessage() => RoverPosition(orientation: orientation);

  @override
  Orientation orientation = Orientation();

  @override
  void update(Orientation newValue) => orientation = newValue.clampHeading();
}
