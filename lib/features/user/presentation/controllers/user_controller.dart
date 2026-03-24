import 'package:uuid/uuid.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/usecases/create_user.dart';
import '../../domain/usecases/set_active_user.dart';

class UserController {
  final CreateUser createUserUsecase;
  final SetActiveUser setActiveUserUsecase;

  UserController({
    required this.createUserUsecase,
    required this.setActiveUserUsecase,
  });

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Nome é obrigatório');
    }

    final user = AppUser(
      id: const Uuid().v4(),
      name: trimmedName,
      email: trimmedEmail.isEmpty ? null : trimmedEmail,
      password: password.trim().isEmpty ? null : password.trim(),
      isActive: false,
      createdAt: DateTime.now(),
    );

    await createUserUsecase(user);
  }

  Future<void> setActiveUser(String userId) async {
    await setActiveUserUsecase(userId);
  }
}