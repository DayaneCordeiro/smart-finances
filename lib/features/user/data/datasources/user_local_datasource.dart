import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/user_model.dart';

class UserLocalDatasource {
  final AppDatabase appDatabase;

  UserLocalDatasource(this.appDatabase);

  Future<Database> get _db async => appDatabase.database;

  Future<void> createUser(UserModel user) async {
    final db = await _db;

    await db.transaction((txn) async {
      final count = Sqflite.firstIntValue(
            await txn.rawQuery('SELECT COUNT(*) FROM users'),
          ) ??
          0;

      final userToInsert = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        password: user.password,
        isActive: count == 0 ? true : user.isActive,
        createdAt: user.createdAt,
      );

      if (userToInsert.isActive) {
        await txn.update('users', {'is_active': 0});
      }

      await txn.insert('users', userToInsert.toMap());
    });
  }

  Future<List<UserModel>> getUsers() async {
    final db = await _db;
    final result = await db.query(
      'users',
      orderBy: 'created_at DESC',
    );

    return result.map(UserModel.fromMap).toList();
  }

  Future<void> setActiveUser(String userId) async {
    final db = await _db;

    await db.transaction((txn) async {
      await txn.update('users', {'is_active': 0});
      await txn.update(
        'users',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [userId],
      );
    });
  }

  Future<UserModel?> getActiveUser() async {
    final db = await _db;

    final result = await db.query(
      'users',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }
}