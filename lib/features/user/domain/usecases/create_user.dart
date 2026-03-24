import '../entities/app_user.dart';
import '../repositories/user_repository.dart';

class CreateUser {
  final UserRepository repository;

  CreateUser(this.repository);

  Future<void> call(AppUser user) async {
    await repository.createUser(user);
  }
}