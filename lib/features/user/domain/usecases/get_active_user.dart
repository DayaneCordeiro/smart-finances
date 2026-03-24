import '../entities/app_user.dart';
import '../repositories/user_repository.dart';

class GetActiveUser {
  final UserRepository repository;

  GetActiveUser(this.repository);

  Future<AppUser?> call() async {
    return repository.getActiveUser();
  }
}