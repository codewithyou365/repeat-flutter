enum GameServerError {
  tokenExpired,
  serviceStopped,
  gameNotFound,
  gameSyncError,
  gameEntryCodeError,
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
}