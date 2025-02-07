import "package:autonomy/autonomy.dart";

class Constants {
  /// The maximum error or "tolerance" for reaching the end goal
  static const double maxErrorMeters = 1;

  /// How close the rover should get to a drive coordinate before
  /// continuing with the path
  static const double intermediateStepTolerance = 0.25;

  /// The amount of meters to move per path step
  static const double moveLengthMeters = 1;

  /// Replan the path if the rover's position is this far away from the path
  static const double replanErrorMeters = 3;

  /// The IMU angle tolerance for a turn during autonomy
  static const double turnEpsilon = 3;

  /// The IMU angle tolerance when turning to re-correct to the
  /// proper orientation before driving forward
  static const double driveRealignmentEpsilon = 5;

  /// The maximum time to spend waiting for the drive to reach a desired GPS coordinate.
  ///
  /// Only applies to individual "drive forward" steps, to prevent indefinite driving
  /// if it never reaches within [maxErrorMeters] of its desired position.
  static const Duration driveGPSTimeout = Duration(seconds: 4, milliseconds: 500);

  /// The maximum time to spend searching for an aruco tag
  static const Duration arucoSearchTimeout = Duration(seconds: 10);

  /// The camera that should be used to detect Aruco tags
  static const CameraName arucoDetectionCamera = CameraName.ROVER_FRONT;
}
