class Constants {
  /// The maximum error or "tolerance" for reaching the end goal
  static const double maxErrorMeters = 1;
  /// The amount of meters to move per path step
  static const double moveLengthMeters = 1;

  /// The IMU angle tolerance for a turn during autonomy
  static const double turnEpsilon = 3;

  /// The IMU angle tolerance when turning to re-correct to the
  /// proper orientation before driving forward
  static const double driveRealignmentEpsilon = 5;
}
