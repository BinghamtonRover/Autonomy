import "dart:async";

import "package:autonomy/src/tank/collection.dart";
import "package:burt_network/burt_network.dart";

class TankDrive extends Service {
  StreamSubscription<DriveCommand>? _subscription;

  @override
  Future<bool> init() async {
    _subscription = tank.server.messages.onMessage<DriveCommand>(
      name: DriveCommand().messageName,
      constructor: DriveCommand.fromBuffer,
      callback: _handleDriveCommand,
    );
    return true;
  }

  @override
  Future<void> onDisconnect() async {
    stop();
    await super.onDisconnect();
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel(); 
  }

  void stop() {
    _setThrottle(0);
    _setSpeeds(left: 0, right: 0);
  }

  void _setThrottle(double throttle) {
    _throttle = throttle;
    _update();
  }

  void _setSpeeds({required double left, required double right}) {
    _leftSpeed = left;
    _rightSpeed = right;
    _update();
  }

  double _leftSpeed = 0;
  double _rightSpeed = 0;
  double _throttle = 0;

  void _handleDriveCommand(DriveCommand command) {
    _leftSpeed = command.setLeft ? command.left : _leftSpeed;
    _rightSpeed = command.setRight ? command.right : _rightSpeed;
    _throttle = command.setThrottle ? command.throttle : _throttle;
    _update();
  }

  void _update() => tank.gpio.updateDrive(left: _leftSpeed, right: _rightSpeed, throttle: _throttle);
}
