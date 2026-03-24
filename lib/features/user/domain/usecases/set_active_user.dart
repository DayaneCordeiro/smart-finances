import '../repositories/user_repository.dart';

class SetActiveUser {
  final UserRepository repository;

  SetActiveUser(this.repository);

  Future<void> call(String userId) async {
    await repository.setActiveUser(userId);
  }
}