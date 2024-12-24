import "package:burt_network/protobuf.dart";

extension OrientationUtils on Orientation {
  static const double epsilon = 3.5;
  static const double orientationEpsilon = 10;

  static final north = Orientation(z: 0);
  static final west = Orientation(z: 90);
  static final south = Orientation(z: 180);
  static final east = Orientation(z: 270);

  double get heading => z;

  bool get isEmpty => x == 0 && y == 0 && z == 0;

  bool isNear(double value) {
    if (value > 270 && z < 90) {
      return (z + 360 - value).abs() < epsilon;
    } else if (value < 90 && z > 270) {
      return (z - value - 360).abs() < epsilon;
    } else {
      return (z - value).abs() < epsilon;
    }
  }
}

extension AngleUtils on double {
  double clampAngle() => ((this % 360) + 360) % 360;
}
