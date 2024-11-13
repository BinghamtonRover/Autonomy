import "dart:async";

import "package:burt_network/burt_network.dart";
import "package:rpi_gpio/gpio.dart";
import "package:rpi_gpio/rpi_gpio.dart";

const leftPinNumber = 13;
const rightPinNumber = 14;

const minVelocity = -1.0;
const maxVelocity = 1.0;

const pwmMaxPos = 82500.0;
const pwmMinPos = 76500.0;
const pwmZero = 75000.0;
const pwmMinNeg = 73500.0;
const pwmMaxNeg = 67500.0;

class Tank extends Service {
  late final server = RoverSocket(port: 8004, device: Device.SUBSYSTEMS, collection: this);

  late RpiGpio gpio;
  late GpioPwm leftPin;
  late GpioPwm rightPin;

  double _leftSpeed = 0;
  double _rightSpeed = 0;
  double _throttle = 0;

  StreamSubscription<DriveCommand>? _subscription;

  @override
  Future<bool> init() async {
    try {
      await server.init();
      _subscription = server.messages.onMessage<DriveCommand>(
        name: DriveCommand().messageName,
        constructor: DriveCommand.fromBuffer,
        callback: _handleDriveCommand,
      );
      gpio = await initialize_RpiGpio();
      leftPin = gpio.pwm(leftPinNumber);
      rightPin = gpio.pwm(rightPinNumber);
      return true;
    } on GpioException {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await server.dispose();
    await gpio.dispose();
  }

  @override
  Future<void> onDisconnect() async {
    _leftSpeed = 0;
    _rightSpeed = 0;
    _throttle = 0;
    _updateMotors();
    await super.onDisconnect();
  }

  void _handleDriveCommand(DriveCommand command) {
    _leftSpeed = command.setLeft ? command.left : _leftSpeed;
    _rightSpeed = command.setRight ? command.right : _rightSpeed;
    _throttle = command.setThrottle ? command.throttle : _throttle;
    _updateMotors();
  }

  void _updateMotors() {
    _setVelocity(leftPin, _leftSpeed * _throttle);
    _setVelocity(rightPin, _rightSpeed * _throttle);
  }

  void _setVelocity(GpioPwm pin, double speed) {
    var pwm = 0.0;
    var velocity = -speed;  // not sure why we negate here
    velocity = velocity.clamp(minVelocity, maxVelocity);
    if (velocity == 0) {
      pwm = pwmZero;
    } else if (velocity > 0) {
      pwm = pwmMinPos + velocity * (pwmMaxPos - pwmMinPos) / maxVelocity;
    } else if (velocity < 0) {
      pwm = pwmMinNeg + velocity * (pwmMaxNeg - pwmMinNeg) / minVelocity;
    }
    pin.dutyCycle = pwm.toInt();
  }
}
