import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/datasources/user_local_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/usecases/create_user.dart';
import '../../domain/usecases/get_active_user.dart';
import '../../domain/usecases/get_users.dart';
import '../../domain/usecases/set_active_user.dart';
import 'user_controller.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final userLocalDatasourceProvider = Provider<UserLocalDatasource>((ref) {
  return UserLocalDatasource(ref.read(appDatabaseProvider));
});

final userRepositoryProvider = Provider<UserRepositoryImpl>((ref) {
  return UserRepositoryImpl(ref.read(userLocalDatasourceProvider));
});

final createUserProvider = Provider<CreateUser>((ref) {
  return CreateUser(ref.read(userRepositoryProvider));
});

final getUsersProvider = Provider<GetUsers>((ref) {
  return GetUsers(ref.read(userRepositoryProvider));
});

final setActiveUserProvider = Provider<SetActiveUser>((ref) {
  return SetActiveUser(ref.read(userRepositoryProvider));
});

final getActiveUserProvider = Provider<GetActiveUser>((ref) {
  return GetActiveUser(ref.read(userRepositoryProvider));
});

final userControllerProvider = Provider<UserController>((ref) {
  return UserController(
    createUserUsecase: ref.read(createUserProvider),
    setActiveUserUsecase: ref.read(setActiveUserProvider),
  );
});

final usersProvider = FutureProvider((ref) async {
  return ref.read(getUsersProvider).call();
});

final activeUserProvider = FutureProvider((ref) async {
  return ref.read(getActiveUserProvider).call();
});