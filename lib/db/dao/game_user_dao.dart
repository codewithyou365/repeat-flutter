// dao/game_dao.dart

import 'package:floor/floor.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/common/hash.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'package:repeat_flutter/db/database.dart';
import 'package:repeat_flutter/db/entity/game_user.dart';
import 'package:repeat_flutter/db/entity/kv.dart';
import 'package:repeat_flutter/logic/game_server/constant.dart';

@dao
abstract class GameUserDao {
  late AppDatabase db;

  // Query to find a user by name.
  @Query('SELECT * FROM GameUser WHERE name = :name')
  Future<GameUser?> findUserByName(String name);

  @Query('SELECT id FROM GameUser WHERE id = :id')
  Future<GameUser?> findUserById(int id);

  @Query('SELECT id FROM GameUser WHERE id = :id')
  Future<int?> findUserIdById(int id);

  @Query('SELECT id FROM GameUser limit 1')
  Future<int?> findFirstUserId();

  @Query('SELECT * FROM GameUser')
  Future<List<GameUser>> getAllUser();

  @Insert(onConflict: OnConflictStrategy.abort)
  Future<int> registerUser(GameUser user);

  @Query('SELECT count(id) FROM GameUser')
  Future<int?> count();

  @Query(
    'UPDATE GameUser SET token=:token,tokenExpiredDate=:tokenExpiredDate'
    ' WHERE id = :id',
  )
  Future<void> updateUserToken(int id, String token, Date tokenExpiredDate);

  @Query(
    'UPDATE GameUser SET token=:token'
    ',tokenExpiredDate=:tokenExpiredDate'
    ',nonce=:nonce'
    ',password=:password'
    ',needToResetPassword=0'
    ' WHERE id = :id',
  )
  Future<void> updateUserTokenWithPassword(
    int id,
    String token,
    Date tokenExpiredDate,
    String nonce,
    String password,
  );

  @Query('SELECT * FROM GameUser WHERE token = :token')
  Future<GameUser?> findUserByToken(String token);

  @Query(
    'UPDATE GameUser SET'
    ' tokenExpiredDate=0'
    ',nonce=:nonce'
    ',password=:password'
    ',needToResetPassword=1'
    ' WHERE id=:id',
  )
  Future<void> innerResetPassword(int id, String nonce, String password);

  @transaction
  Future<String> resetPassword(int id) async {
    final existingUser = await findUserIdById(id);
    if (existingUser == null) {
      return '';
    }
    final nonce = StringUtil.generateRandomString(32);
    final password = StringUtil.generateRandom09(6);
    final passwordHash = Hash.toSha1ForString(password + nonce);
    await innerResetPassword(id, nonce, passwordHash);
    return password;
  }

  @transaction
  Future<String> loginOrRegister(String name, String password, String newPassword, List<String> error) async {
    final now = DateTime.now();
    if (name.isEmpty || password.isEmpty) {
      error.add(GameServerError.userOrPasswordError.name);
      return '';
    }
    final existingUser = await findUserByName(name);
    if (existingUser == null) {
      final nonce = StringUtil.generateRandomString(32);
      final passwordHash = Hash.toSha1ForString(password + nonce);
      int? registrations = await count();
      registrations ??= 0;
      int allowRegisterNumber = await db.kvDao.getInt(K.allowRegisterNumber) ?? 1;
      if (registrations >= allowRegisterNumber) {
        error.add(GameServerError.excessRegisterCount.name);
        return '';
      }
      final newUser = GameUser(
        name: name,
        password: passwordHash,
        nonce: nonce,
        createDate: Date.from(now),
        token: StringUtil.generateRandomString(32),
        tokenExpiredDate: Date.from(now.add(const Duration(days: 7))),
        needToResetPassword: false,
      );
      await registerUser(newUser);
      return newUser.token;
    } else {
      final passwordHash = Hash.toSha1ForString(password + existingUser.nonce);
      if (existingUser.password != passwordHash) {
        error.add(GameServerError.userOrPasswordError.name);
        return '';
      }
      final String token = StringUtil.generateRandomString(32);
      existingUser.token = token;
      existingUser.tokenExpiredDate = Date.from(now.add(const Duration(days: 7)));
      if (existingUser.needToResetPassword) {
        if (newPassword.isEmpty) {
          error.add(GameServerError.needToResetPassword.name);
          return '';
        }
        final nonce = StringUtil.generateRandomString(32);
        final newPasswordHash = Hash.toSha1ForString(newPassword + nonce);
        await updateUserTokenWithPassword(
          existingUser.id!,
          token,
          existingUser.tokenExpiredDate,
          nonce,
          newPasswordHash,
        );
        existingUser.needToResetPassword = false;
      } else {
        await updateUserToken(
          existingUser.id!,
          token,
          existingUser.tokenExpiredDate,
        );
      }

      return existingUser.token;
    }
  }

  @transaction
  Future<GameUser> authByToken(String token) async {
    if (token.isEmpty) {
      return GameUser.empty();
    }
    final user = await findUserByToken(token);
    final now = DateTime.now();
    final Date date = Date.from(now);
    if (user == null || user.tokenExpiredDate.value < date.value) {
      return GameUser.empty();
    }

    return user;
  }
}
