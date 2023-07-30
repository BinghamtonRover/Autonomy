import "package:burt_network/burt_network.dart";
import "package:rpi_gpio/rpi_gpio.dart";

const minVelocity = -1;
const maxVelocity = 1;
const leftPin = 13;
const rightPin = 12;

const double pwmMaxNeg = 67500;
const double pwmMinNeg = 73500;
const double pwmZero = 75000;
const double pwmMinPos = 76500;
const double pwmMaxPos = 82500;

// TODO: Set frequency

class TankSubsystems extends ServerSocket {
	late final RpiGpio pi;
	TankSubsystems() : super(port: 8001, device: Device.SUBSYSTEMS);

	double throttle = 0;
	double leftVelocity = 0;
	double rightVelocity = 0;

	@override
	Future<void> init() async {
		// pi = await initialize_RpiGpio();
		await super.init();
	}

	@override
	Future<void> dispose() async {
		await pi.dispose();
		await super.dispose();
	}

	@override
	void onMessage(WrappedMessage wrapper) {
		if (wrapper.name == DriveCommand().messageName) {
			final command = DriveCommand.fromBuffer(wrapper.data);
			logger.info("Received DriveCommand: $command");
			if (command.setThrottle) throttle = command.throttle;
			if (command.setLeft) leftVelocity = -command.left;
			if (command.setRight) rightVelocity = -command.right;
			updateMotors();
		}
	}

	void updateMotors() {
		setVelocity(leftPin, leftVelocity * throttle);
		setVelocity(rightPin, rightVelocity * throttle);
	}

	void setVelocity(int pin, double velocity) {
		final double pwmValue;
		// ignore: parameter_assignments
		velocity = velocity.clamp(minVelocity, maxVelocity).toDouble();
		if (velocity == 0) {
			pwmValue = pwmZero;
		} else if (velocity > 0) {
			pwmValue = pwmMinPos + velocity * (pwmMaxPos - pwmMinPos);
		} else {
			pwmValue = pwmMinNeg + velocity * (pwmMaxNeg - pwmMinNeg) * -1;
		}
		pi.pwm(pin).dutyCycle = pwmValue.round();
	}
}

void main() async {
	logger.info("Controlling the tank");
	final server = TankSubsystems();
	await server.init();
}
