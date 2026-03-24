import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/category_model.dart';

class CategoryLocalDatasource {
  final AppDatabase appDatabase;

  CategoryLocalDatasource(this.appDatabase);

  Future<Database> get _db async => appDatabase.database;

  Future<void> createCategory(CategoryModel category) async {
    final db = await _db;
    await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getCategoriesByUser(String userId) async {
    final db = await _db;

    final result = await db.query(
      'categories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return result.map(CategoryModel.fromMap).toList();
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await _db;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }
}