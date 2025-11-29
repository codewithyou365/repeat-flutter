import 'package:repeat_flutter/i18n/i18n_key.dart';

enum GameServerError {
  tokenExpired,
  needToResetPassword,
  userOrPasswordError,
  excessRegisterCount,
  serviceStopped,
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
  static const getEditStatus = '/api/getEditStatus';
  static const getVerseContent = '/api/getVerseContent';
  static const setVerseContent = '/api/setVerseContent';
}

enum GameTypeEnum {
  none(I18nKey.none),
  type(I18nKey.typeGame),
  blankItRight(I18nKey.blankItRightGame),
  input(I18nKey.inputGame);

  final I18nKey i18n;

  const GameTypeEnum(this.i18n);
}
