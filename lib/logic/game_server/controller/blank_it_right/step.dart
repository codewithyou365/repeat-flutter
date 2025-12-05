enum StepEnum {
  none,
  blanking,
  blanked,
  finished,
}

class UserData {
  StepEnum step;
  String submit;

  UserData({
    required this.step,
    required this.submit,
  });
}

class Step {
  static Map<int, UserData> userStep = {};

  static void blanking({
    required List<int> userIds,
  }) {
    userStep.clear();
    for (var userId in userIds) {
      userStep[userId] = UserData(step: StepEnum.blanking, submit: '');
    }
  }

  static void blanked() {
    for (var userId in userStep.keys) {
      userStep[userId] = UserData(step: StepEnum.blanked, submit: '');
    }
  }

  static void finished({required int userId, required String submit}) {
    userStep[userId] = UserData(step: StepEnum.finished, submit: submit);
  }

  static StepEnum getStepEnum({
    required int userId,
  }) {
    var ret = userStep[userId];
    if (ret == null) {
      return StepEnum.none;
    }
    return ret.step;
  }

  static String getSubmit({
    required int userId,
  }) {
    var ret = userStep[userId];
    if (ret == null) {
      return '';
    }
    return ret.submit;
  }
}
