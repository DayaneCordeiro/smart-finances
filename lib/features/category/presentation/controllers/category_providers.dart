import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../user/presentation/controllers/user_providers.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/usecases/create_category.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/get_categories_by_user.dart';
import 'category_controller.dart';

final categoryLocalDatasourceProvider = Provider<CategoryLocalDatasource>((ref) {
  return CategoryLocalDatasource(ref.read(appDatabaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepositoryImpl>((ref) {
  return CategoryRepositoryImpl(ref.read(categoryLocalDatasourceProvider));
});

final createCategoryProvider = Provider<CreateCategory>((ref) {
  return CreateCategory(ref.read(categoryRepositoryProvider));
});

final getCategoriesByUserProvider = Provider<GetCategoriesByUser>((ref) {
  return GetCategoriesByUser(ref.read(categoryRepositoryProvider));
});

final deleteCategoryProvider = Provider<DeleteCategory>((ref) {
  return DeleteCategory(ref.read(categoryRepositoryProvider));
});

final categoryControllerProvider = Provider<CategoryController>((ref) {
  return CategoryController(
    createCategoryUsecase: ref.read(createCategoryProvider),
    deleteCategoryUsecase: ref.read(deleteCategoryProvider),
  );
});

final categoriesProvider =
    FutureProvider.family((ref, String userId) async {
  return ref.read(getCategoriesByUserProvider).call(userId);
});