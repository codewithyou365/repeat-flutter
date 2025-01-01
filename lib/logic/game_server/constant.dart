enum GameServerError {
  tokenExpired,
  gameNotFound,
}

class GameServerPath {
  static const String assetsPath = "assets/game";
}

class PlaceholderToken {
  static const String using = '•';
  static const String replace = '·';
}
