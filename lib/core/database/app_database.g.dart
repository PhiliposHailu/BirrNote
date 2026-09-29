// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _rawNoteMeta = const VerificationMeta(
    'rawNote',
  );
  @override
  late final GeneratedColumn<String> rawNote = GeneratedColumn<String>(
    'raw_note',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Others'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isPendingAiMeta = const VerificationMeta(
    'isPendingAi',
  );
  @override
  late final GeneratedColumn<bool> isPendingAi = GeneratedColumn<bool>(
    'is_pending_ai',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_ai" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _txnRefMeta = const VerificationMeta('txnRef');
  @override
  late final GeneratedColumn<String> txnRef = GeneratedColumn<String>(
    'txn_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rawNote,
    amount,
    category,
    date,
    quantity,
    isPendingAi,
    source,
    txnRef,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('raw_note')) {
      context.handle(
        _rawNoteMeta,
        rawNote.isAcceptableOrUnknown(data['raw_note']!, _rawNoteMeta),
      );
    } else if (isInserting) {
      context.missing(_rawNoteMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('is_pending_ai')) {
      context.handle(
        _isPendingAiMeta,
        isPendingAi.isAcceptableOrUnknown(
          data['is_pending_ai']!,
          _isPendingAiMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('txn_ref')) {
      context.handle(
        _txnRefMeta,
        txnRef.isAcceptableOrUnknown(data['txn_ref']!, _txnRefMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      rawNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_note'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      isPendingAi: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_ai'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      txnRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}txn_ref'],
      ),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final int id;
  final String rawNote;
  final double amount;
  final String category;
  final DateTime date;
  final int quantity;
  final bool isPendingAi;
  final String source;
  final String? txnRef;
  const Expense({
    required this.id,
    required this.rawNote,
    required this.amount,
    required this.category,
    required this.date,
    required this.quantity,
    required this.isPendingAi,
    required this.source,
    this.txnRef,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['raw_note'] = Variable<String>(rawNote);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    map['date'] = Variable<DateTime>(date);
    map['quantity'] = Variable<int>(quantity);
    map['is_pending_ai'] = Variable<bool>(isPendingAi);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || txnRef != null) {
      map['txn_ref'] = Variable<String>(txnRef);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      rawNote: Value(rawNote),
      amount: Value(amount),
      category: Value(category),
      date: Value(date),
      quantity: Value(quantity),
      isPendingAi: Value(isPendingAi),
      source: Value(source),
      txnRef: txnRef == null && nullToAbsent
          ? const Value.absent()
          : Value(txnRef),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<int>(json['id']),
      rawNote: serializer.fromJson<String>(json['rawNote']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      date: serializer.fromJson<DateTime>(json['date']),
      quantity: serializer.fromJson<int>(json['quantity']),
      isPendingAi: serializer.fromJson<bool>(json['isPendingAi']),
      source: serializer.fromJson<String>(json['source']),
      txnRef: serializer.fromJson<String?>(json['txnRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rawNote': serializer.toJson<String>(rawNote),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'date': serializer.toJson<DateTime>(date),
      'quantity': serializer.toJson<int>(quantity),
      'isPendingAi': serializer.toJson<bool>(isPendingAi),
      'source': serializer.toJson<String>(source),
      'txnRef': serializer.toJson<String?>(txnRef),
    };
  }

  Expense copyWith({
    int? id,
    String? rawNote,
    double? amount,
    String? category,
    DateTime? date,
    int? quantity,
    bool? isPendingAi,
    String? source,
    Value<String?> txnRef = const Value.absent(),
  }) => Expense(
    id: id ?? this.id,
    rawNote: rawNote ?? this.rawNote,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
    quantity: quantity ?? this.quantity,
    isPendingAi: isPendingAi ?? this.isPendingAi,
    source: source ?? this.source,
    txnRef: txnRef.present ? txnRef.value : this.txnRef,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      rawNote: data.rawNote.present ? data.rawNote.value : this.rawNote,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      date: data.date.present ? data.date.value : this.date,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      isPendingAi: data.isPendingAi.present
          ? data.isPendingAi.value
          : this.isPendingAi,
      source: data.source.present ? data.source.value : this.source,
      txnRef: data.txnRef.present ? data.txnRef.value : this.txnRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('rawNote: $rawNote, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('isPendingAi: $isPendingAi, ')
          ..write('source: $source, ')
          ..write('txnRef: $txnRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rawNote,
    amount,
    category,
    date,
    quantity,
    isPendingAi,
    source,
    txnRef,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.rawNote == this.rawNote &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.date == this.date &&
          other.quantity == this.quantity &&
          other.isPendingAi == this.isPendingAi &&
          other.source == this.source &&
          other.txnRef == this.txnRef);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<int> id;
  final Value<String> rawNote;
  final Value<double> amount;
  final Value<String> category;
  final Value<DateTime> date;
  final Value<int> quantity;
  final Value<bool> isPendingAi;
  final Value<String> source;
  final Value<String?> txnRef;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.rawNote = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
    this.quantity = const Value.absent(),
    this.isPendingAi = const Value.absent(),
    this.source = const Value.absent(),
    this.txnRef = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required String rawNote,
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    required DateTime date,
    this.quantity = const Value.absent(),
    this.isPendingAi = const Value.absent(),
    this.source = const Value.absent(),
    this.txnRef = const Value.absent(),
  }) : rawNote = Value(rawNote),
       date = Value(date);
  static Insertable<Expense> custom({
    Expression<int>? id,
    Expression<String>? rawNote,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<DateTime>? date,
    Expression<int>? quantity,
    Expression<bool>? isPendingAi,
    Expression<String>? source,
    Expression<String>? txnRef,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawNote != null) 'raw_note': rawNote,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (quantity != null) 'quantity': quantity,
      if (isPendingAi != null) 'is_pending_ai': isPendingAi,
      if (source != null) 'source': source,
      if (txnRef != null) 'txn_ref': txnRef,
    });
  }

  ExpensesCompanion copyWith({
    Value<int>? id,
    Value<String>? rawNote,
    Value<double>? amount,
    Value<String>? category,
    Value<DateTime>? date,
    Value<int>? quantity,
    Value<bool>? isPendingAi,
    Value<String>? source,
    Value<String?>? txnRef,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      rawNote: rawNote ?? this.rawNote,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      isPendingAi: isPendingAi ?? this.isPendingAi,
      source: source ?? this.source,
      txnRef: txnRef ?? this.txnRef,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rawNote.present) {
      map['raw_note'] = Variable<String>(rawNote.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (isPendingAi.present) {
      map['is_pending_ai'] = Variable<bool>(isPendingAi.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (txnRef.present) {
      map['txn_ref'] = Variable<String>(txnRef.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('rawNote: $rawNote, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('isPendingAi: $isPendingAi, ')
          ..write('source: $source, ')
          ..write('txnRef: $txnRef')
          ..write(')'))
        .toString();
  }
}

class $CategoryOptionsTable extends CategoryOptions
    with TableInfo<$CategoryOptionsTable, CategoryOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryOption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryOption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryOption(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $CategoryOptionsTable createAlias(String alias) {
    return $CategoryOptionsTable(attachedDatabase, alias);
  }
}

class CategoryOption extends DataClass implements Insertable<CategoryOption> {
  final int id;
  final String name;
  final int orderIndex;
  const CategoryOption({
    required this.id,
    required this.name,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  CategoryOptionsCompanion toCompanion(bool nullToAbsent) {
    return CategoryOptionsCompanion(
      id: Value(id),
      name: Value(name),
      orderIndex: Value(orderIndex),
    );
  }

  factory CategoryOption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryOption(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  CategoryOption copyWith({int? id, String? name, int? orderIndex}) =>
      CategoryOption(
        id: id ?? this.id,
        name: name ?? this.name,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  CategoryOption copyWithCompanion(CategoryOptionsCompanion data) {
    return CategoryOption(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOption(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryOption &&
          other.id == this.id &&
          other.name == this.name &&
          other.orderIndex == this.orderIndex);
}

class CategoryOptionsCompanion extends UpdateCompanion<CategoryOption> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> orderIndex;
  const CategoryOptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.orderIndex = const Value.absent(),
  });
  CategoryOptionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.orderIndex = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CategoryOption> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? orderIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (orderIndex != null) 'order_index': orderIndex,
    });
  }

  CategoryOptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? orderIndex,
  }) {
    return CategoryOptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _limitAmountMeta = const VerificationMeta(
    'limitAmount',
  );
  @override
  late final GeneratedColumn<double> limitAmount = GeneratedColumn<double>(
    'limit_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Weekly'),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, limitAmount, period, startDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('limit_amount')) {
      context.handle(
        _limitAmountMeta,
        limitAmount.isAcceptableOrUnknown(
          data['limit_amount']!,
          _limitAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitAmountMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      limitAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}limit_amount'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;
  final double limitAmount;
  final String period;
  final DateTime startDate;
  const Budget({
    required this.id,
    required this.limitAmount,
    required this.period,
    required this.startDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['limit_amount'] = Variable<double>(limitAmount);
    map['period'] = Variable<String>(period);
    map['start_date'] = Variable<DateTime>(startDate);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      limitAmount: Value(limitAmount),
      period: Value(period),
      startDate: Value(startDate),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      limitAmount: serializer.fromJson<double>(json['limitAmount']),
      period: serializer.fromJson<String>(json['period']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'limitAmount': serializer.toJson<double>(limitAmount),
      'period': serializer.toJson<String>(period),
      'startDate': serializer.toJson<DateTime>(startDate),
    };
  }

  Budget copyWith({
    int? id,
    double? limitAmount,
    String? period,
    DateTime? startDate,
  }) => Budget(
    id: id ?? this.id,
    limitAmount: limitAmount ?? this.limitAmount,
    period: period ?? this.period,
    startDate: startDate ?? this.startDate,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      limitAmount: data.limitAmount.present
          ? data.limitAmount.value
          : this.limitAmount,
      period: data.period.present ? data.period.value : this.period,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('period: $period, ')
          ..write('startDate: $startDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, limitAmount, period, startDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.limitAmount == this.limitAmount &&
          other.period == this.period &&
          other.startDate == this.startDate);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<double> limitAmount;
  final Value<String> period;
  final Value<DateTime> startDate;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.limitAmount = const Value.absent(),
    this.period = const Value.absent(),
    this.startDate = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    required double limitAmount,
    this.period = const Value.absent(),
    required DateTime startDate,
  }) : limitAmount = Value(limitAmount),
       startDate = Value(startDate);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<double>? limitAmount,
    Expression<String>? period,
    Expression<DateTime>? startDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (limitAmount != null) 'limit_amount': limitAmount,
      if (period != null) 'period': period,
      if (startDate != null) 'start_date': startDate,
    });
  }

  BudgetsCompanion copyWith({
    Value<int>? id,
    Value<double>? limitAmount,
    Value<String>? period,
    Value<DateTime>? startDate,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      limitAmount: limitAmount ?? this.limitAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (limitAmount.present) {
      map['limit_amount'] = Variable<double>(limitAmount.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('period: $period, ')
          ..write('startDate: $startDate')
          ..write(')'))
        .toString();
  }
}

class $AmortizationsTable extends Amortizations
    with TableInfo<$AmortizationsTable, Amortization> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmortizationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<int> expenseId = GeneratedColumn<int>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES expenses(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationDaysMeta = const VerificationMeta(
    'durationDays',
  );
  @override
  late final GeneratedColumn<int> durationDays = GeneratedColumn<int>(
    'duration_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyBurdenMeta = const VerificationMeta(
    'dailyBurden',
  );
  @override
  late final GeneratedColumn<double> dailyBurden = GeneratedColumn<double>(
    'daily_burden',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseId,
    totalAmount,
    durationDays,
    dailyBurden,
    startDate,
    endDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'amortizations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Amortization> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('duration_days')) {
      context.handle(
        _durationDaysMeta,
        durationDays.isAcceptableOrUnknown(
          data['duration_days']!,
          _durationDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationDaysMeta);
    }
    if (data.containsKey('daily_burden')) {
      context.handle(
        _dailyBurdenMeta,
        dailyBurden.isAcceptableOrUnknown(
          data['daily_burden']!,
          _dailyBurdenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyBurdenMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Amortization map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Amortization(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expense_id'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      durationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_days'],
      )!,
      dailyBurden: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}daily_burden'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
    );
  }

  @override
  $AmortizationsTable createAlias(String alias) {
    return $AmortizationsTable(attachedDatabase, alias);
  }
}

class Amortization extends DataClass implements Insertable<Amortization> {
  final int id;
  final int expenseId;
  final double totalAmount;
  final int durationDays;
  final double dailyBurden;
  final DateTime startDate;
  final DateTime endDate;
  const Amortization({
    required this.id,
    required this.expenseId,
    required this.totalAmount,
    required this.durationDays,
    required this.dailyBurden,
    required this.startDate,
    required this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['expense_id'] = Variable<int>(expenseId);
    map['total_amount'] = Variable<double>(totalAmount);
    map['duration_days'] = Variable<int>(durationDays);
    map['daily_burden'] = Variable<double>(dailyBurden);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    return map;
  }

  AmortizationsCompanion toCompanion(bool nullToAbsent) {
    return AmortizationsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      totalAmount: Value(totalAmount),
      durationDays: Value(durationDays),
      dailyBurden: Value(dailyBurden),
      startDate: Value(startDate),
      endDate: Value(endDate),
    );
  }

  factory Amortization.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Amortization(
      id: serializer.fromJson<int>(json['id']),
      expenseId: serializer.fromJson<int>(json['expenseId']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      durationDays: serializer.fromJson<int>(json['durationDays']),
      dailyBurden: serializer.fromJson<double>(json['dailyBurden']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'expenseId': serializer.toJson<int>(expenseId),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'durationDays': serializer.toJson<int>(durationDays),
      'dailyBurden': serializer.toJson<double>(dailyBurden),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
    };
  }

  Amortization copyWith({
    int? id,
    int? expenseId,
    double? totalAmount,
    int? durationDays,
    double? dailyBurden,
    DateTime? startDate,
    DateTime? endDate,
  }) => Amortization(
    id: id ?? this.id,
    expenseId: expenseId ?? this.expenseId,
    totalAmount: totalAmount ?? this.totalAmount,
    durationDays: durationDays ?? this.durationDays,
    dailyBurden: dailyBurden ?? this.dailyBurden,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
  );
  Amortization copyWithCompanion(AmortizationsCompanion data) {
    return Amortization(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      durationDays: data.durationDays.present
          ? data.durationDays.value
          : this.durationDays,
      dailyBurden: data.dailyBurden.present
          ? data.dailyBurden.value
          : this.dailyBurden,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Amortization(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('durationDays: $durationDays, ')
          ..write('dailyBurden: $dailyBurden, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    expenseId,
    totalAmount,
    durationDays,
    dailyBurden,
    startDate,
    endDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Amortization &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.totalAmount == this.totalAmount &&
          other.durationDays == this.durationDays &&
          other.dailyBurden == this.dailyBurden &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class AmortizationsCompanion extends UpdateCompanion<Amortization> {
  final Value<int> id;
  final Value<int> expenseId;
  final Value<double> totalAmount;
  final Value<int> durationDays;
  final Value<double> dailyBurden;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  const AmortizationsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.durationDays = const Value.absent(),
    this.dailyBurden = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
  });
  AmortizationsCompanion.insert({
    this.id = const Value.absent(),
    required int expenseId,
    required double totalAmount,
    required int durationDays,
    required double dailyBurden,
    required DateTime startDate,
    required DateTime endDate,
  }) : expenseId = Value(expenseId),
       totalAmount = Value(totalAmount),
       durationDays = Value(durationDays),
       dailyBurden = Value(dailyBurden),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<Amortization> custom({
    Expression<int>? id,
    Expression<int>? expenseId,
    Expression<double>? totalAmount,
    Expression<int>? durationDays,
    Expression<double>? dailyBurden,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (durationDays != null) 'duration_days': durationDays,
      if (dailyBurden != null) 'daily_burden': dailyBurden,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
  }

  AmortizationsCompanion copyWith({
    Value<int>? id,
    Value<int>? expenseId,
    Value<double>? totalAmount,
    Value<int>? durationDays,
    Value<double>? dailyBurden,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
  }) {
    return AmortizationsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      totalAmount: totalAmount ?? this.totalAmount,
      durationDays: durationDays ?? this.durationDays,
      dailyBurden: dailyBurden ?? this.dailyBurden,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<int>(expenseId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (durationDays.present) {
      map['duration_days'] = Variable<int>(durationDays.value);
    }
    if (dailyBurden.present) {
      map['daily_burden'] = Variable<double>(dailyBurden.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmortizationsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('durationDays: $durationDays, ')
          ..write('dailyBurden: $dailyBurden, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $CategoryOptionsTable categoryOptions = $CategoryOptionsTable(
    this,
  );
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $AmortizationsTable amortizations = $AmortizationsTable(this);
  late final ExpenseDao expenseDao = ExpenseDao(this as AppDatabase);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final BudgetDao budgetDao = BudgetDao(this as AppDatabase);
  late final AmortizationDao amortizationDao = AmortizationDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    expenses,
    categoryOptions,
    budgets,
    amortizations,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'expenses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('amortizations', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      Value<int> id,
      required String rawNote,
      Value<double> amount,
      Value<String> category,
      required DateTime date,
      Value<int> quantity,
      Value<bool> isPendingAi,
      Value<String> source,
      Value<String?> txnRef,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<int> id,
      Value<String> rawNote,
      Value<double> amount,
      Value<String> category,
      Value<DateTime> date,
      Value<int> quantity,
      Value<bool> isPendingAi,
      Value<String> source,
      Value<String?> txnRef,
    });

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AmortizationsTable, List<Amortization>>
  _amortizationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.amortizations,
    aliasName: $_aliasNameGenerator(db.expenses.id, db.amortizations.expenseId),
  );

  $$AmortizationsTableProcessedTableManager get amortizationsRefs {
    final manager = $$AmortizationsTableTableManager(
      $_db,
      $_db.amortizations,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_amortizationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawNote => $composableBuilder(
    column: $table.rawNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingAi => $composableBuilder(
    column: $table.isPendingAi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get txnRef => $composableBuilder(
    column: $table.txnRef,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> amortizationsRefs(
    Expression<bool> Function($$AmortizationsTableFilterComposer f) f,
  ) {
    final $$AmortizationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amortizations,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmortizationsTableFilterComposer(
            $db: $db,
            $table: $db.amortizations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawNote => $composableBuilder(
    column: $table.rawNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingAi => $composableBuilder(
    column: $table.isPendingAi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get txnRef => $composableBuilder(
    column: $table.txnRef,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawNote =>
      $composableBuilder(column: $table.rawNote, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<bool> get isPendingAi => $composableBuilder(
    column: $table.isPendingAi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get txnRef =>
      $composableBuilder(column: $table.txnRef, builder: (column) => column);

  Expression<T> amortizationsRefs<T extends Object>(
    Expression<T> Function($$AmortizationsTableAnnotationComposer a) f,
  ) {
    final $$AmortizationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amortizations,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmortizationsTableAnnotationComposer(
            $db: $db,
            $table: $db.amortizations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, $$ExpensesTableReferences),
          Expense,
          PrefetchHooks Function({bool amortizationsRefs})
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> rawNote = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<bool> isPendingAi = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> txnRef = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                rawNote: rawNote,
                amount: amount,
                category: category,
                date: date,
                quantity: quantity,
                isPendingAi: isPendingAi,
                source: source,
                txnRef: txnRef,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String rawNote,
                Value<double> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                required DateTime date,
                Value<int> quantity = const Value.absent(),
                Value<bool> isPendingAi = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> txnRef = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                rawNote: rawNote,
                amount: amount,
                category: category,
                date: date,
                quantity: quantity,
                isPendingAi: isPendingAi,
                source: source,
                txnRef: txnRef,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({amortizationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (amortizationsRefs) db.amortizations,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (amortizationsRefs)
                    await $_getPrefetchedData<
                      Expense,
                      $ExpensesTable,
                      Amortization
                    >(
                      currentTable: table,
                      referencedTable: $$ExpensesTableReferences
                          ._amortizationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ExpensesTableReferences(
                        db,
                        table,
                        p0,
                      ).amortizationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.expenseId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, $$ExpensesTableReferences),
      Expense,
      PrefetchHooks Function({bool amortizationsRefs})
    >;
typedef $$CategoryOptionsTableCreateCompanionBuilder =
    CategoryOptionsCompanion Function({
      Value<int> id,
      required String name,
      Value<int> orderIndex,
    });
typedef $$CategoryOptionsTableUpdateCompanionBuilder =
    CategoryOptionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> orderIndex,
    });

class $$CategoryOptionsTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryOptionsTable> {
  $$CategoryOptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryOptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryOptionsTable> {
  $$CategoryOptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryOptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryOptionsTable> {
  $$CategoryOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );
}

class $$CategoryOptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryOptionsTable,
          CategoryOption,
          $$CategoryOptionsTableFilterComposer,
          $$CategoryOptionsTableOrderingComposer,
          $$CategoryOptionsTableAnnotationComposer,
          $$CategoryOptionsTableCreateCompanionBuilder,
          $$CategoryOptionsTableUpdateCompanionBuilder,
          (
            CategoryOption,
            BaseReferences<
              _$AppDatabase,
              $CategoryOptionsTable,
              CategoryOption
            >,
          ),
          CategoryOption,
          PrefetchHooks Function()
        > {
  $$CategoryOptionsTableTableManager(
    _$AppDatabase db,
    $CategoryOptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryOptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryOptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryOptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
              }) => CategoryOptionsCompanion(
                id: id,
                name: name,
                orderIndex: orderIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> orderIndex = const Value.absent(),
              }) => CategoryOptionsCompanion.insert(
                id: id,
                name: name,
                orderIndex: orderIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryOptionsTable,
      CategoryOption,
      $$CategoryOptionsTableFilterComposer,
      $$CategoryOptionsTableOrderingComposer,
      $$CategoryOptionsTableAnnotationComposer,
      $$CategoryOptionsTableCreateCompanionBuilder,
      $$CategoryOptionsTableUpdateCompanionBuilder,
      (
        CategoryOption,
        BaseReferences<_$AppDatabase, $CategoryOptionsTable, CategoryOption>,
      ),
      CategoryOption,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      Value<int> id,
      required double limitAmount,
      Value<String> period,
      required DateTime startDate,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<int> id,
      Value<double> limitAmount,
      Value<String> period,
      Value<DateTime> startDate,
    });

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
          Budget,
          PrefetchHooks Function()
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> limitAmount = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                limitAmount: limitAmount,
                period: period,
                startDate: startDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double limitAmount,
                Value<String> period = const Value.absent(),
                required DateTime startDate,
              }) => BudgetsCompanion.insert(
                id: id,
                limitAmount: limitAmount,
                period: period,
                startDate: startDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
      Budget,
      PrefetchHooks Function()
    >;
typedef $$AmortizationsTableCreateCompanionBuilder =
    AmortizationsCompanion Function({
      Value<int> id,
      required int expenseId,
      required double totalAmount,
      required int durationDays,
      required double dailyBurden,
      required DateTime startDate,
      required DateTime endDate,
    });
typedef $$AmortizationsTableUpdateCompanionBuilder =
    AmortizationsCompanion Function({
      Value<int> id,
      Value<int> expenseId,
      Value<double> totalAmount,
      Value<int> durationDays,
      Value<double> dailyBurden,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
    });

final class $$AmortizationsTableReferences
    extends BaseReferences<_$AppDatabase, $AmortizationsTable, Amortization> {
  $$AmortizationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExpensesTable _expenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias(
        $_aliasNameGenerator(db.amortizations.expenseId, db.expenses.id),
      );

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<int>('expense_id')!;

    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AmortizationsTableFilterComposer
    extends Composer<_$AppDatabase, $AmortizationsTable> {
  $$AmortizationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dailyBurden => $composableBuilder(
    column: $table.dailyBurden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmortizationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AmortizationsTable> {
  $$AmortizationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dailyBurden => $composableBuilder(
    column: $table.dailyBurden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmortizationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AmortizationsTable> {
  $$AmortizationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dailyBurden => $composableBuilder(
    column: $table.dailyBurden,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmortizationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AmortizationsTable,
          Amortization,
          $$AmortizationsTableFilterComposer,
          $$AmortizationsTableOrderingComposer,
          $$AmortizationsTableAnnotationComposer,
          $$AmortizationsTableCreateCompanionBuilder,
          $$AmortizationsTableUpdateCompanionBuilder,
          (Amortization, $$AmortizationsTableReferences),
          Amortization,
          PrefetchHooks Function({bool expenseId})
        > {
  $$AmortizationsTableTableManager(_$AppDatabase db, $AmortizationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmortizationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmortizationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmortizationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> expenseId = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<int> durationDays = const Value.absent(),
                Value<double> dailyBurden = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
              }) => AmortizationsCompanion(
                id: id,
                expenseId: expenseId,
                totalAmount: totalAmount,
                durationDays: durationDays,
                dailyBurden: dailyBurden,
                startDate: startDate,
                endDate: endDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int expenseId,
                required double totalAmount,
                required int durationDays,
                required double dailyBurden,
                required DateTime startDate,
                required DateTime endDate,
              }) => AmortizationsCompanion.insert(
                id: id,
                expenseId: expenseId,
                totalAmount: totalAmount,
                durationDays: durationDays,
                dailyBurden: dailyBurden,
                startDate: startDate,
                endDate: endDate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AmortizationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expenseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (expenseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.expenseId,
                                referencedTable: $$AmortizationsTableReferences
                                    ._expenseIdTable(db),
                                referencedColumn: $$AmortizationsTableReferences
                                    ._expenseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AmortizationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AmortizationsTable,
      Amortization,
      $$AmortizationsTableFilterComposer,
      $$AmortizationsTableOrderingComposer,
      $$AmortizationsTableAnnotationComposer,
      $$AmortizationsTableCreateCompanionBuilder,
      $$AmortizationsTableUpdateCompanionBuilder,
      (Amortization, $$AmortizationsTableReferences),
      Amortization,
      PrefetchHooks Function({bool expenseId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$CategoryOptionsTableTableManager get categoryOptions =>
      $$CategoryOptionsTableTableManager(_db, _db.categoryOptions);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$AmortizationsTableTableManager get amortizations =>
      $$AmortizationsTableTableManager(_db, _db.amortizations);
}
