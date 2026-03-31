import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/datasources/credit_card_adjustment_local_datasource.dart';
import '../../data/repositories/credit_card_adjustment_repository_impl.dart';
import '../../domain/entities/credit_card_adjustment.dart';
import '../../domain/repositories/credit_card_adjustment_repository.dart';

final creditCardAdjustmentAppDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final creditCardAdjustmentLocalDataSourceProvider =
    Provider<CreditCardAdjustmentLocalDataSource>((ref) {
  return CreditCardAdjustmentLocalDataSource(
    ref.read(creditCardAdjustmentAppDatabaseProvider),
  );
});

final creditCardAdjustmentRepositoryProvider =
    Provider<CreditCardAdjustmentRepository>((ref) {
  return CreditCardAdjustmentRepositoryImpl(
    ref.read(creditCardAdjustmentLocalDataSourceProvider),
  );
});

@immutable
class CreditCardAdjustmentQuery {
  final String userId;
  final String creditCardId;

  const CreditCardAdjustmentQuery({
    required this.userId,
    required this.creditCardId,
  });

  @override
  bool operator ==(Object other) {
    return other is CreditCardAdjustmentQuery &&
        other.userId == userId &&
        other.creditCardId == creditCardId;
  }

  @override
  int get hashCode => Object.hash(userId, creditCardId);
}

final creditCardAdjustmentsByCardProvider = FutureProvider.family<
    List<CreditCardAdjustment>,
    CreditCardAdjustmentQuery>((ref, query) async {
  return ref.read(creditCardAdjustmentRepositoryProvider).getAdjustmentsByCard(
        userId: query.userId,
        creditCardId: query.creditCardId,
      );
});