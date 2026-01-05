enum GameServerError {
  tokenExpired,
  gamePasswordError,
  needToResetPassword,
  userOrPasswordError,
  excessRegisterCount,
  serviceStopped,
  scoreMustBePositive,
  noData,
  editorUserNeedToBeSpecified,
  editorUserInvalid,
  submitUserInvalid,
  gameNotReady,
  gameStateInvalid,
  gameNotFound,
  gameSyncError,
  gameEntryCodeError,
  contentNotFound,
  editModeDisabled,
  contentCantBeSave,
  wordSlicerMustHaveJudge,
  wordSlicerDifferentColorUserCountMustBeMoreThanTwo,
}

class GameConstant {
  static const String assetsPath = "assets/game";
}

class PlaceholderToken {
  static const String using = '•';
  static const String replace = '·';
}

class Path {
  static const kick = '/api/kick';
  static const refreshGame = '/api/refreshGame';
  static const wordSlicerStatusUpdate = '/api/wordSlicerStatusUpdate';

  static const loginOrRegister = '/api/loginOrRegister';
  static const entryGame = '/api/entryGame';
  static const heart = '/api/heart';
  static const gameUserHistory = '/api/gameUserHistory';
  static const submit = '/api/submit';
  static const gameUserScore = '/api/gameUserScore';
  static const gameUserScoreHistory = '/api/gameUserScoreHistory';
  static const gameUserScoreMinus = '/api/gameUserScoreMinus';
  static const typeGameSettings = '/api/typeGameSettings';
  static const typeVerseContent = '/api/typeVerseContent';
  static const blankItRightSettings = '/api/blankItRightSettings';
  static const blankItRightContent = '/api/blankItRightContent';
  static const blankItRightBlank = '/api/blankItRightBlank';
  static const blankItRightSubmit = '/api/blankItRightSubmit';
  static const wordSlicerStatus = '/api/wordSlicerStatus';
  static const wordSlicerSelectRole = '/api/wordSlicerSelectRole';
  static const wordSlicerStartGame = '/api/wordSlicerStartGame';
  static const wordSlicerSubmit = '/api/wordSlicerSubmit';
  static const wordSlicerEdit = '/api/wordSlicerEdit';


}
