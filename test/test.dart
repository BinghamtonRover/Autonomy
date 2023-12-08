class SubsystemsData{
  final RoverPosition position;
}

class Drive{
  void SetSpeed(double left, double right){
    final command = DriveCommand(left:left, set_left:true)
    final command2 = DriveCommand(right:right, set_right:true)
  }
  void Stop(){}
  void SetThrottle(double){}
}