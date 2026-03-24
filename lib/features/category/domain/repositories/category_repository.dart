import '../entities/app_category.dart';

abstract class CategoryRepository {
  Future<void> createCategory(AppCategory category);
  Future<List<AppCategory>> getCategoriesByUser(String userId);
  Future<void> deleteCategory(String categoryId);
}