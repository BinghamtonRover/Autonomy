import "dart:async";

import "package:autonomy/constants.dart";
import "package:autonomy/interfaces.dart";
import "package:collection/collection.dart";

class RoverVideo extends VideoInterface {
  final List<VisionResult> _cachedResults = [];

  RoverVideo({required super.collection});

  @override
  Future<bool> init() async {
    collection.server.messages.onMessage(
      name: VisionResult().messageName,
      constructor: VisionResult.fromBuffer,
      callback: updateFrame,
    );
    return true;
  }

  @override
  Future<void> dispose() async {}

  @override
  void updateFrame(VisionResult result) {
    hasValue = true;
    if (result.objects.isEmpty) return;

    _cachedResults.removeWhere((e) => e.name == result.name);

    _cachedResults.add(result);
  }

  @override
  DetectedObject? getArucoDetection(int id, {CameraName? desiredCamera}) {
    for (final result in _cachedResults.where((e) => e.name == (desiredCamera ?? e.name))) {
      for (final object in result.objects) {
        if (object.arucoTagId == id) {
          return object;
        }
      }
    }
    return null;
  }

  @override
  Future<DetectedObject?> waitForAruco(
    int id, {
    CameraName? desiredCamera,
    Duration timeout = Constants.arucoSearchTimeout,
  }) async {
    final completer = Completer<DetectedObject>();

    late final StreamSubscription<VisionResult> resultSubscription;

    resultSubscription = collection.server.messages.onMessage(
      name: VisionResult().messageName,
      constructor: VisionResult.fromBuffer,
      callback: (result) async {
        if (result.name != (desiredCamera ?? result.name)) return;
        final object = result.objects.firstWhereOrNull((e) => e.arucoTagId == id);
        if (object != null) {
          await resultSubscription.cancel();
          completer.complete(object);
        }
      },
    );
    
    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      await resultSubscription.cancel();
      return null;
    }
  }
}
