import 'package:repeat_flutter/common/ws/server.dart';

class EditorUser extends UserId {
  int credential;

  EditorUser({required this.credential});

  @override
  int getId() {
    return credential;
  }
}
