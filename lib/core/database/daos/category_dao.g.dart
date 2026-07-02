// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoryOptionsTable get categoryOptions => attachedDatabase.categoryOptions;
  CategoryDaoManager get managers => CategoryDaoManager(this);
}

class CategoryDaoManager {
  final _$CategoryDaoMixin _db;
  CategoryDaoManager(this._db);
  $$CategoryOptionsTableTableManager get categoryOptions =>
      $$CategoryOptionsTableTableManager(
        _db.attachedDatabase,
        _db.categoryOptions,
      );
}
