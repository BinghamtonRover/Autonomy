import "dart:async";
import "package:burt_network/generated.dart";

import "package:autonomy/interfaces.dart";

mixin ValueReporter {
  AutonomyInterface get collection;
  Message getMessage();

  Timer? timer;
  static const reportInterval = Duration(milliseconds: 250);
  void init() => timer = Timer.periodic(reportInterval, (timer) => reportValue());
  void dispose() => timer?.cancel();
  void reportValue() => collection.server.sendMessage(getMessage());
}
