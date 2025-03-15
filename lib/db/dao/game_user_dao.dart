// dao/game_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/kv.dart';

@dao
abstract class GameUserDao {
  // Query to find a user by name.
  @Query('SELECT * FROM GameUser WHERE name = :name')
  Future<GameUser?> findUserByName(String name);

  @Query('SELECT * FROM GameUser')
  Future<List<GameUser>> getAllUser();

  @Query("SELECT CAST(value as INTEGER) FROM Kv where `k`=:k")
  Future<int?> intKv(K k);

  // Insert a new user into the database.
  @Insert(onConflict: OnConflictStrategy.abort)
  Future<int> registerUser(GameUser user);

  @Query('SELECT count(id) FROM GameUser')
  Future<int?> count();

  @Query('UPDATE GameUser SET token=:token,tokenExpiredDate=:tokenExpiredDate WHERE id = :id')
  Future<void> updateUserToken(int id, String token, Date tokenExpiredDate);

  @Query('SELECT * FROM GameUser WHERE token = :token')
  Future<GameUser?> findUserByToken(String token);

  @transaction
  Future<String> loginOrRegister(String name, String password) async {
    final now = DateTime.now();
    final existingUser = await findUserByName(name);
    if (existingUser == null) {
      final nonce = StringUtil.generateRandomString(32);
      final passwordHash = Hash.toSha1ForString(password + nonce);
      int? registrations = await count();
      registrations ??= 0;
      int allowRegisterNumber = await intKv(K.allowRegisterNumber) ?? 1;
      if (registrations >= allowRegisterNumber) {
        return '';
      }
      final newUser = GameUser(
        name,
        passwordHash,
        nonce,
        Date.from(now),
        StringUtil.generateRandomString(32),
        Date.from(now.add(const Duration(days: 7))),
      );
      await registerUser(newUser);
      return newUser.token;
    } else {
      final passwordHash = await Hash.toSha1ForString(password + existingUser.nonce);
      if (existingUser.password != passwordHash) {
        return '';
      }
      final String token = StringUtil.generateRandomString(32);
      existingUser.token = token;
      existingUser.tokenExpiredDate = Date.from(now.add(const Duration(days: 7)));
      await updateUserToken(existingUser.id!, token, existingUser.tokenExpiredDate!);
      return existingUser.token;
    }
  }

  @transaction
  Future<GameUser> loginByToken(String token) async {
    if (token.isEmpty) {
      return GameUser.empty();
    }
    final user = await findUserByToken(token);
    final now = DateTime.now();
    final Date date = Date.from(now);
    if (user == null || user.tokenExpiredDate == null || user.tokenExpiredDate!.value < date.value) {
      return GameUser.empty();
    }

    return user;
  }
}
