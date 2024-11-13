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

const dataInterval = Duration(milliseconds: 250);
final driveVersion = Version(major: 1, minor: 1);

class Tank extends Service {
  late final server = RoverSocket(port: 8001, device: Device.SUBSYSTEMS, collection: this);
  late final logger = BurtLogger(socket: server);

  double _leftSpeed = 0;
  double _rightSpeed = 0;
  double _throttle = 0;

  RpiGpio? gpio;
  GpioPwm? leftPin;
  GpioPwm? rightPin;

  StreamSubscription<DriveCommand>? _subscription;
  Timer? _dataTimer;

  @override
  Future<bool> init() async {
    try {
      await server.init();
      _subscription = server.messages.onMessage<DriveCommand>(
        name: DriveCommand().messageName,
        constructor: DriveCommand.fromBuffer,
        callback: _handleDriveCommand,
      );
      _dataTimer = Timer.periodic(dataInterval, _sendData);
      gpio = await initialize_RpiGpio();
      leftPin = gpio?.pwm(leftPinNumber);
      rightPin = gpio?.pwm(rightPinNumber);
      return true;
    } catch (error) {
      logger.critical("Could not initialize the Tank", body: error.toString());
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _dataTimer?.cancel();
    await _subscription?.cancel();
    await server.dispose();
    await gpio?.dispose();
  }

  @override
  Future<void> onDisconnect() async {
    _leftSpeed = 0;
    _rightSpeed = 0;
    _throttle = 0;
    _updateMotors();
    await super.onDisconnect();
  }

  void _sendData(Timer t) => server.sendMessage(DriveData(
    setLeft: true, left: _leftSpeed,
    setRight: true, right: _rightSpeed,
    setThrottle: true, throttle: _throttle,
    version: driveVersion,
  ),);

  void _handleDriveCommand(DriveCommand command) {
    _leftSpeed = command.setLeft ? command.left : _leftSpeed;
    _rightSpeed = command.setRight ? command.right : _rightSpeed;
    _throttle = command.setThrottle ? command.throttle : _throttle;
    _updateMotors();
  }

  void _updateMotors() {
    if (gpio == null) return;
    _setVelocity(leftPin!, _leftSpeed * _throttle);
    _setVelocity(rightPin!, _rightSpeed * _throttle);
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
