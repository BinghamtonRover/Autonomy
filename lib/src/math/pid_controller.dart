import "dart:math";

class PIDController {
  double kP;
  double kI;
  double kD;

  double maxIntegral = 1;
  double minIntegral = -1;
  double iZone = double.infinity;

  double setpoint = 0;

  Duration period;

  bool continuous;
  double maxInput = pi / 2;
  double minInput = -pi / 2;

  PIDController({
    required this.kP,
    required this.period,
    this.kI = 0,
    this.kD = 0,
    this.continuous = false,
  });

  double _previousError = 0;
  double _totalError = 0;

  double get totalError => _totalError;

  double get _periodSeconds => (period.inMicroseconds) / 1e6;

  double inputModulus(double input, double minInput, double maxInput) {
    var output = input;
    final modulus = maxInput - minInput;

    final numMax = ((output - minInput) / modulus).toInt();
    output -= numMax * modulus;

    final numMin = ((output - maxInput) / modulus).toInt();

    return output -= numMin * modulus;
  }

  double calculate(double measurement, double setpoint) {
    this.setpoint = setpoint;

    double error;
    if (continuous) {
      final errorBound = (maxInput - minInput) / 2;
      error = inputModulus(setpoint - measurement, -errorBound, errorBound);
    } else {
      error = setpoint - measurement;
    }

    final errorDerivative = (error - _previousError) / _periodSeconds;

    if (error.abs() > iZone) {
      _totalError = 0;
    } else if (kI != 0) {
      _totalError = (_totalError + error * _periodSeconds)
          .clamp(minIntegral / kI, maxIntegral / kI);
    }

    _previousError = error;

    return error * kP + _totalError * kI + errorDerivative * kD;
  }

  void reset() {
    _previousError = 0;
    _totalError = 0;
  }
}
