import "dart:async";
import "dart:math";

import "package:autonomy/interfaces.dart";

class RoverDetector extends DetectorInterface {
  StreamSubscription<LidarPointCloud>? _subscription;

  LidarPointCloud cloudCache = LidarPointCloud();

  List<GpsCoordinates> queuedObstacles = [];

  RoverDetector({required super.collection});

  void _handleLidarCloud(LidarPointCloud cloud) {
    if (cloud.cartesian.isNotEmpty) {
      cloudCache.cartesian.clear();
      cloudCache.cartesian.addAll(cloud.cartesian);
    }
    if (cloud.polar.isNotEmpty) {
      cloudCache.polar.clear();
      cloudCache.polar.addAll(cloud.polar);
    }

    _queueObstacles();
  }

  void _queueObstacles() {
    final cartesian = cloudCache.cartesian;
    final polar = cloudCache.polar;

    if (cartesian.isEmpty || polar.isEmpty) {
      return;
    }

    for (final point in cartesian) {
      final angle = atan2(point.y, point.x) * 180 / pi;
      final magnitude = sqrt(pow(point.x, 2) + pow(point.y, 2));

      final matchingPolar = polar.where((e) =>
            (e.angle - angle.roundToDouble()).abs() <= 1 &&
            (e.angle - angle.roundToDouble()).abs() != 0,
      );

      // no polar coordinates are near the cartesian coordinate
      if (matchingPolar.isEmpty) {
        continue;
      }
      // nearby polar coordinates do not match the cartesian distance, likely a false speck
      if (!matchingPolar.any((e) => (e.distance - magnitude).abs() < 0.05)) {
        continue;
      }

      final imuAngleRad = collection.imu.heading * pi / 180;

      final roverToPoint = (
        long: point.x * cos(imuAngleRad) - (-point.y) * sin(imuAngleRad),
        lat: (-point.y) * cos(imuAngleRad) + point.x * sin(imuAngleRad)
      );

      queuedObstacles.add(
        (collection.gps.coordinates.inMeters + roverToPoint).toGps(),
      );
    }

    cloudCache.cartesian.clear();
    cloudCache.polar.clear();
  }

  @override
  bool isOnSlope() => false;

  @override
  bool findObstacles() {
    if (queuedObstacles.isEmpty) return false;

    for (final obstacle in queuedObstacles) {
      collection.pathfinder.recordObstacle(obstacle);
    }

    queuedObstacles.clear();

    return true;
  }

  @override
  Future<bool> init() async {
    _subscription = collection.server.messages.onMessage(
      name: LidarPointCloud().messageName,
      constructor: LidarPointCloud.fromBuffer,
      callback: _handleLidarCloud,
    );
    return true;
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
