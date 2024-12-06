import "package:autonomy/interfaces.dart";
import "package:burt_network/burt_network.dart";

abstract class ImuInterface extends Service with Receiver {
  final AutonomyInterface collection;
  ImuInterface({required this.collection});

  double get heading => raw.z;
  Orientation get raw;

  CardinalDirection get nearest => CardinalDirection.nearest(raw);

  void update(Orientation newValue);
  bool isNear(CardinalDirection direction) => raw.isNear(direction.angle);

  @override
  Future<bool> init() async => true;
}
