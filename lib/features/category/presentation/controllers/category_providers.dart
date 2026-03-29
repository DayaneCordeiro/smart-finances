import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/app_category.dart';

final categoryDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final expenseCategoriesProvider =
    FutureProvider.family<List<AppCategory>, String>((ref, userId) async {
  final appDatabase = ref.read(categoryDatabaseProvider);

  await appDatabase.ensureDefaultCategoriesForUser(userId);

  final db = await appDatabase.database;
  final result = await db.query(
    'categories',
    where: 'user_id = ? AND type = ?',
    whereArgs: [userId, 'expense'],
    orderBy: '''
      CASE id
        WHEN 'fixed_expense' THEN 1
        WHEN 'variable_expense' THEN 2
        WHEN 'extra_expense' THEN 3
        WHEN 'financing_expense' THEN 4
        ELSE 99
      END
    ''',
  );

  return result.map((map) {
    return AppCategory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }).toList();
});