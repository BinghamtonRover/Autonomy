import "package:burt_network/burt_network.dart";
import "package:rpi_gpio/gpio.dart";
import "package:rpi_gpio/rpi_gpio.dart";

class GpioService extends Service {
  static const leftPinNumber = 13;
  static const rightPinNumber = 14;

  static const minVelocity = -1.0;
  static const maxVelocity = 1.0;

  static const pwmMaxPos = 82500.0;
  static const pwmMinPos = 76500.0;
  static const pwmZero = 75000.0;
  static const pwmMinNeg = 73500.0;
  static const pwmMaxNeg = 67500.0;

  late final RpiGpio gpio;
  late final GpioPwm leftPin;
  late final GpioPwm rightPin;

  @override
  Future<bool> init() async {
    try {
      gpio = await initialize_RpiGpio();
      leftPin = gpio.pwm(leftPinNumber);
      rightPin = gpio.pwm(rightPinNumber);
      return true;
    } on GpioException {
      return false;
    }
  }

  @override
  Future<void> dispose() => gpio.dispose();

  void updateDrive({required double left, required double right, required double throttle}) {
    _setVelocity(leftPin, left * throttle);
    _setVelocity(rightPin, right * throttle);
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
