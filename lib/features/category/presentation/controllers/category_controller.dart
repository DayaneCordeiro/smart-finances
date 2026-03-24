import 'package:uuid/uuid.dart';

import '../../domain/entities/app_category.dart';
import '../../domain/usecases/create_category.dart';
import '../../domain/usecases/delete_category.dart';

class CategoryController {
  final CreateCategory createCategoryUsecase;
  final DeleteCategory deleteCategoryUsecase;

  CategoryController({
    required this.createCategoryUsecase,
    required this.deleteCategoryUsecase,
  });

  Future<void> createCategory({
    required String userId,
    required String name,
    required String type,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Nome da categoria é obrigatório');
    }

    final category = AppCategory(
      id: const Uuid().v4(),
      userId: userId,
      name: trimmedName,
      type: type,
      createdAt: DateTime.now(),
    );

    await createCategoryUsecase(category);
  }

  Future<void> deleteCategory(String categoryId) async {
    await deleteCategoryUsecase(categoryId);
  }
}