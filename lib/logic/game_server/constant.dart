import 'package:repeat_flutter/i18n/i18n_key.dart';

enum GameServerError {
  tokenExpired,
  needToResetPassword,
  userOrPasswordError,
  excessRegisterCount,
  serviceStopped,

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

  static const loginOrRegister = '/api/loginOrRegister';
  static const entryGame = '/api/entryGame';
  static const heart = '/api/heart';
  static const gameUserHistory = '/api/gameUserHistory';
  static const submit = '/api/submit';
  static const typeGameSettings = '/api/typeGameSettings';
  static const typeVerseContent = '/api/typeVerseContent';
  static const blankItRightSettings = '/api/blankItRightSettings';
  static const blankItRightContent = '/api/blankItRightContent';
  static const blankItRightBlank = '/api/blankItRightBlank';
  static const blankItRightSubmit = '/api/blankItRightSubmit';
}

enum GameTypeEnum {
  none(I18nKey.none),
  type(I18nKey.typeGame),
  blankItRight(I18nKey.blankItRightGame),
  input(I18nKey.inputGame);

  final I18nKey i18n;

  const GameTypeEnum(this.i18n);
}
