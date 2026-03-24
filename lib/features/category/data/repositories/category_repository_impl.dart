import '../../domain/entities/app_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDatasource localDatasource;

  CategoryRepositoryImpl(this.localDatasource);

  @override
  Future<void> createCategory(AppCategory category) async {
    await localDatasource.createCategory(CategoryModel.fromEntity(category));
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await localDatasource.deleteCategory(categoryId);
  }

  @override
  Future<List<AppCategory>> getCategoriesByUser(String userId) async {
    final categories = await localDatasource.getCategoriesByUser(userId);
    return categories.map((e) => e.toEntity()).toList();
  }
}