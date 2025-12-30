enum GameStepEnum {
  none,
  selectRule,
  started,
}

WordSlicerGame wordSlicerGame = WordSlicerGame();

class WordSlicerGame {
  GameStepEnum gameStep = GameStepEnum.selectRule;
  List<List<int>> colorIndexToUserId = [[], [], []];
  List<int> userIds = [];
  Map<String, String> userIdToUserName = {};
  int currUserIndex = -1;
  int judgeUserId = -1;

  void clear() {
    gameStep = GameStepEnum.selectRule;
    colorIndexToUserId = [[], [], []];
    userIds = [];
    userIdToUserName = {};
    currUserIndex = -1;
    judgeUserId = -1;
  }

  Map<String, dynamic> toJson() {
    return {
      'gameStep': gameStep.name,
      'colorIndexToUserId': colorIndexToUserId,
      'userIds': userIds,
      'userIdToUserName': userIdToUserName,
      'currUserIndex': currUserIndex,
      'judgeUserId': judgeUserId,
    };
  }
}
