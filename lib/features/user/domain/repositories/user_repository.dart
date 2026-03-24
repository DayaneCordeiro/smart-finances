import '../entities/app_user.dart';

abstract class UserRepository {
  Future<void> createUser(AppUser user);
  Future<List<AppUser>> getUsers();
  Future<void> setActiveUser(String userId);
  Future<AppUser?> getActiveUser();
}