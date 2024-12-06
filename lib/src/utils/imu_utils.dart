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

  Orientation clampHeading() {
    var adjustedHeading = heading;
    if (heading >= 360) adjustedHeading -= 360;
    if (heading < 0) adjustedHeading = 360 + heading;
    return Orientation(x: x, y: y, z: adjustedHeading);
  }

  bool isNear(double value, [double tolerance = epsilon]) => value > 270 && z < 90
    ? (z + 360 - value).abs() < tolerance
    : value < 90 && z > 270
      ? (z - value - 360).abs() < tolerance
      : (z - value).abs() < tolerance;
}
