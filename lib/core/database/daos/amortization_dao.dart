import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/amortizations_table.dart';

part 'amortization_dao.g.dart';

@DriftAccessor(tables: [Amortizations])
class AmortizationDao extends DatabaseAccessor<AppDatabase>
    with _$AmortizationDaoMixin {
  AmortizationDao(super.db);

  Stream<List<Amortization>> watchAllAmortizations() =>
      select(amortizations).watch();

  Future<List<Amortization>> getAllAmortizations() =>
      select(amortizations).get();

  Stream<List<Amortization>> watchActiveAmortizations(DateTime now) {
    final nowMidnight = DateTime(now.year, now.month, now.day);
    return (select(amortizations)..where(
          (tbl) =>
              tbl.startDate.isSmallerOrEqualValue(nowMidnight) &
              tbl.endDate.isBiggerThanValue(nowMidnight),
        ))
        .watch();
  }

  Future<int> insertAmortization(AmortizationsCompanion companion) =>
      into(amortizations).insert(companion);

  Future<int> deleteAmortizationByExpenseId(int expenseId) => (delete(
    amortizations,
  )..where((tbl) => tbl.expenseId.equals(expenseId))).go();

  Future<Amortization?> getAmortizationForExpense(int expenseId) => (select(
    amortizations,
  )..where((tbl) => tbl.expenseId.equals(expenseId))).getSingleOrNull();
}
