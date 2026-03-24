import '../entities/app_category.dart';
import '../repositories/category_repository.dart';

class CreateCategory {
  final CategoryRepository repository;

  CreateCategory(this.repository);

  Future<void> call(AppCategory category) async {
    await repository.createCategory(category);
  }
}