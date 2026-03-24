import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDatasource localDatasource;

  UserRepositoryImpl(this.localDatasource);

  @override
  Future<void> createUser(AppUser user) async {
    await localDatasource.createUser(UserModel.fromEntity(user));
  }

  @override
  Future<List<AppUser>> getUsers() async {
    final users = await localDatasource.getUsers();
    return users.map((e) => e.toEntity()).toList();
  }

  @override
  Future<AppUser?> getActiveUser() async {
    final user = await localDatasource.getActiveUser();
    return user?.toEntity();
  }

  @override
  Future<void> setActiveUser(String userId) async {
    await localDatasource.setActiveUser(userId);
  }
}