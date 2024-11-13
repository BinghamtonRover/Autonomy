import "package:burt_network/burt_network.dart";

import "drive.dart";
import "gpio.dart";

class TankCollection extends Service {
  late final server = RoverSocket(port: 8001, device: Device.SUBSYSTEMS, collection: this);

  final drive = TankDrive();
  final gpio = GpioService();

  @override
  Future<bool> init() async {
    var result = true;
    result &= await server.init();
    result &= await gpio.init();
    result &= await drive.init();
    return result;
  }

  @override
  Future<void> onDisconnect() async {
    drive.stop();
    await super.onDisconnect();
  }

  @override
  Future<void> dispose() async {
    await drive.dispose();
    await gpio.dispose();
  }
}

final tank = TankCollection();

final logger = BurtLogger(socket: tank.server);
