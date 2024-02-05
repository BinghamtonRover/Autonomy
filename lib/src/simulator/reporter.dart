import "dart:async";
import "package:burt_network/generated.dart";

import "package:autonomy/interfaces.dart";

mixin ValueReporter {
  AutonomyInterface get collection;
  Message getMessage();

  Timer? timer;
  static const reportInterval = Duration(milliseconds: 100);
  Future<void> init() async => timer = Timer.periodic(reportInterval, (timer) => reportValue());
  Future<void> dispose() async => timer?.cancel();
  void reportValue() => collection.server.sendMessage(getMessage());
}
