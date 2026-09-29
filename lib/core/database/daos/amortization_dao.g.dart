// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'amortization_dao.dart';

// ignore_for_file: type=lint
mixin _$AmortizationDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExpensesTable get expenses => attachedDatabase.expenses;
  $AmortizationsTable get amortizations => attachedDatabase.amortizations;
  AmortizationDaoManager get managers => AmortizationDaoManager(this);
}

class AmortizationDaoManager {
  final _$AmortizationDaoMixin _db;
  AmortizationDaoManager(this._db);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db.attachedDatabase, _db.expenses);
  $$AmortizationsTableTableManager get amortizations =>
      $$AmortizationsTableTableManager(_db.attachedDatabase, _db.amortizations);
}
