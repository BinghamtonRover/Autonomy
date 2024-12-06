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

  bool isNear(double value, [double tolerance = epsilon]) => value > 270 && z < 90
    ? (z + 360 - value).abs() < tolerance
    : value < 90 && z > 270
      ? (z - value - 360).abs() < tolerance
      : (z - value).abs() < tolerance;
}

extension AngleUtils on double {
  double clampAngle() {
    if (this >= 360) {
      return this - 360;
    } else if (this < 0) {
      return this + 360;
    } else {
      return this;
    }
  }
}
