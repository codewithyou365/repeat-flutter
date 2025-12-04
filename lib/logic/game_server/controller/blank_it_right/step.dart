enum StepEnum {
  none,
  blanking,
  blanked,
}

class Step {
  static String lastKey = "";
  static StepEnum lastStep = StepEnum.blanking;

  static StepEnum getStepEnum(int gameId, int time) {
    var currKey = "$gameId:$time";
    if (currKey != lastKey) {
      return StepEnum.blanking;
    }
    return lastStep;
  }

  static void setStepEnum(int gameId, int time, StepEnum step) {
    var currKey = "$gameId:$time";
    lastKey = currKey;
    lastStep = step;
  }
}
