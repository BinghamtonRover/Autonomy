import "package:autonomy/autonomy.dart";

extension OrientationUtils on Orientation {
  /// The IMU angle tolerance for a turn during autonomy
  static const double turnEpsilon = 5;
  /// The IMU angle tolerance when turning to re-correct to the
  /// proper orientation before driving forward
  static const double driveRealignmentEpsilon = 8;

  /// North orientation
  static final north = Orientation(z: CardinalDirection.north.angle);
  /// East orientation
  static final west = Orientation(z: CardinalDirection.west.angle);
  /// South Orientation
  static final south = Orientation(z: CardinalDirection.south.angle);
  /// East orientation
  static final east = Orientation(z: CardinalDirection.east.angle);

  /// The heading of the orientation, or the compass direction we are facing
  double get heading => z;

  /// Whether or not this orientation is within [epsilon] degrees of [value]
  bool isNear(double value, [double? epsilon]) {
    epsilon ??= OrientationUtils.turnEpsilon;
    final error = (value - z).clampHalfAngle();

    return error.abs() <= epsilon;
    // if (value > 270 && z < 90) {
    //   return (z + 360 - value).abs() < epsilon;
    // } else if (value < 90 && z > 270) {
    //   return (z - value - 360).abs() < epsilon;
    // } else {
    //   return (z - value).abs() < epsilon;
    // }
  }
}

/// Utility methods for an angle
extension AngleUtils on double {
  /// The angle clamped between (-180, 180)
  double clampHalfAngle() => ((this + 180) % 360) - 180;
  /// The angle clamped between (0, 360)
  double clampAngle() => ((this % 360) + 360) % 360;
}
