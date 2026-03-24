import '../repositories/category_repository.dart';

class DeleteCategory {
  final CategoryRepository repository;

  DeleteCategory(this.repository);

  Future<void> call(String categoryId) async {
    await repository.deleteCategory(categoryId);
  }
}