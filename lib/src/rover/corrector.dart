import "dart:collection";

class ErrorCorrector {  // non-nullable
  final int maxSamples;
  final double maxDeviation;
  ErrorCorrector({this.maxSamples = 5, this.maxDeviation = double.infinity});
  
  double calibratedValue = 0;
  final Queue<double> recentSamples = DoubleLinkedQueue();
  
  void addValue(double value) {
    if (recentSamples.isEmpty) {
      recentSamples.add(value);
      calibratedValue = value;
      return;
    }
    final deviation = (calibratedValue - value).abs();
    if (deviation > maxDeviation) {
      // print("Threw out value");
    }
    if (recentSamples.length == maxSamples) recentSamples.removeLast();
    recentSamples.addFirst(value);
    calibratedValue = recentSamples.average();
  }
}

extension on Iterable<num> {
  double average() {
    num sum = 0;
    var count = 0;
    for (final element in this) {
      sum += element; 
      count++;
    }
    return sum / count;
  }
}
