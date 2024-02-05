import "package:burt_network/generated.dart";
import "package:autonomy/interfaces.dart";

class ImuSimulator extends ImuInterface with ValueReporter {  
  ImuSimulator({required super.collection});
  
  @override
  RoverPosition getMessage() => RoverPosition(orientation: orientation);
}
