import 'package:repeat_flutter/common/ws/message.dart' as message;
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/classroom.dart';
import 'package:repeat_flutter/db/entity/cr_kv.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';
import 'package:repeat_flutter/logic/widget/game/game_state.dart';

class Kv {
  final String k;
  final String v;

  Kv({
    required this.k,
    required this.v,
  });

  Map<String, dynamic> toJson() {
    return {
      'k': k,
      'v': v,
    };
  }

  factory Kv.fromJson(Map<String, dynamic> json) {
    return Kv(
      k: json['k'] as String,
      v: json['v'] as String,
    );
  }
}

class GetGameSettingsRes {
  final List<Kv> list;

  GetGameSettingsRes(this.list);

  Map<String, dynamic> toJson() {
    return {
      'list': list.map((e) => e.toJson()).toList(),
    };
  }

  factory GetGameSettingsRes.fromJson(Map<String, dynamic> json) {
    return GetGameSettingsRes(
      (json['list'] as List<dynamic>).map((e) => Kv.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

Future<message.Response?> getGameSettings(message.Request req, GameUser? user) async {
  if (user == null) {
    return message.Response(error: GameServerError.serviceStopped.name);
  }
  var res = GetGameSettingsRes([]);
  if (GameState.lastGameIndex == GameTypeEnum.type.index) {
    var ignorePunctuation = false;
    var kip = await Db().db.crKvDao.getInt(Classroom.curr, CrK.typeGameForIgnorePunctuation);
    if (kip != null) {
      ignorePunctuation = kip == 1;
    }
    var ignoreCase = false;
    var kic = await Db().db.crKvDao.getInt(Classroom.curr, CrK.typeGameForIgnoreCase);
    if (kic != null) {
      ignoreCase = kic == 1;
    }
    res.list.add(Kv(k: CrK.typeGameForIgnorePunctuation.name, v: "$ignorePunctuation"));
    res.list.add(Kv(k: CrK.typeGameForIgnoreCase.name, v: "$ignoreCase"));
  }

  return message.Response(data: res);
}
