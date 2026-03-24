import '../entities/app_category.dart';
import '../repositories/category_repository.dart';

class GetCategoriesByUser {
  final CategoryRepository repository;

  GetCategoriesByUser(this.repository);

  Future<List<AppCategory>> call(String userId) async {
    return repository.getCategoriesByUser(userId);
  }
}