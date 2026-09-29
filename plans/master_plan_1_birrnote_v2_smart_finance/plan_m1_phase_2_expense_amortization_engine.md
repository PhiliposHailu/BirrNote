# Phase 2 Plan — Expense Amortization Engine ("Spread the Burden")

> **Master Plan:** [Master Plan 1 — BirrNote v2.0: Smart Finance Engine](file:///home/philipos/Desktop/Dev/birr_note/plans/master_plan_1_birrnote_v2_smart_finance/master_plan_1_birrnote_v2_smart_finance.md)  
> **Status:** Completed — Audited & Verified  
> **Target Package:** `birr_note`  
> **Scope:** Drift DB schema v4 migration, straight-line daily amortization calculation, budget engine integration, manual entry amortization controls, and live spending power indicators  

---

## 1. Executive Summary & Problem Statement

Currently in BirrNote, every logged expense is immediately deducted as a lump sum from the user's spending power on the day of entry. 

**The Pain Point:**
* Daily budget limit: **100 ETB / day**
* User purchases a monthly internet package or telecom top-up: **350 ETB**
* Current spending power: $100 - 350 = \mathbf{-250\text{ ETB}}$
* **Result:** The user's daily budget is ruined for days, rendering the app's primary tracking feature discouraging and unusable.

**Phase 2 Solution:**
* Allow users to toggle **"Spread Cost"** when logging an expense and pick a duration (e.g. 7 days, 14 days, 30 days, or custom).
* Create a dedicated Drift database table `Amortizations` linked to the original expense.
* Update [`budget_providers.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/data/budget_providers.dart):
  * Exclude the full lump-sum amount of amortized expenses from the cycle's standard expense sum.
  * Instead, calculate and apply the daily straight-line burden ($350 / 7 = 50\text{ ETB/day}$) for each active day within the active budget cycle.
  * Historical reports and pie charts retain the full 350 ETB under the original expense record for accounting integrity.
* Display active amortization status on the spending power card in [`budget_header_widget.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/presentation/widgets/budget_header_widget.dart).

---

## 2. UI/UX & HCI Principles Alignment

Per the platform's [Zero-Clutter Standard](file:///home/philipos/Desktop/Dev/.agents/rules/ui-ux-design-principles.md):
- **Cognitive Load Reduction & Progressive Disclosure:**
  * In [`manual_entry_sheet.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/presentation/widgets/manual_entry_sheet.dart), the amortization controls are collapsed behind a single clean switch: **Spread Cost**.
  * Duration chips and preview only appear when toggled ON.
- **Recognition Over Recall:**
  * Quick-tap preset chips for common durations: `[7 Days]`, `[14 Days]`, `[30 Days]`, alongside a `[Custom]` option.
  * Real-time live preview card: dynamically calculates and displays:  
    `✦ 50.00 ETB/day for 7 days` directly beneath the selection.
- **Trust & Transparency (Financial Invariants):**
  * Straight-line calculation with zero hidden fees or math rounding drift.
  * The spending power card in [`budget_header_widget.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/presentation/widgets/budget_header_widget.dart) displays an informative badge: `2 active installments • 65 ETB/day burden`.
- **Mobile Ergonomics & Fitts's Law:**
  * All preset chips and buttons maintain a touch target of at least **44x44px**.
  * Input fields default to `TextInputType.number` for frictionless mobile numeric input.
- **Zero Jargon:**
  * Uses friendly plain English copy ("Spread Cost", "Daily Burden", "Installments") instead of accounting jargon like "Depreciation Schedule".

---

## 3. Architecture & File Matrix

```
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart            # [MODIFY] Register Amortizations & DAO, bump to v4, add migration
│   │   ├── database_provider.dart       # [MODIFY] Expose amortizationDaoProvider
│   │   ├── daos/
│   │   │   ├── amortization_dao.dart    # [CREATE] CRUD queries & watchActiveAmortizations()
│   │   │   └── expense_dao.dart         # [MODIFY] Ensure cascade/cleanup when deleting expense
│   │   └── tables/
│   │       ├── amortizations_table.dart # [CREATE] Drift table schema
│   │       └── expenses_table.dart      # [MODIFY] Add source & txnRef columns (schema v4)
│   └── utils/
│       └── app_translations.dart        # [MODIFY] 4-language localization keys
└── features/
    └── expense_entry/
        ├── data/
        │   ├── budget_providers.dart    # [MODIFY] Incorporate daily amortization burden
        │   └── expense_providers.dart   # [MODIFY] Add amortization params to addManualExpense
        └── presentation/
            └── widgets/
                ├── manual_entry_sheet.dart   # [MODIFY] Add Spread Cost toggle, preset chips, live preview
                └── budget_header_widget.dart # [MODIFY] Add active installments indicator badge
test/
└── amortization_engine_test.dart        # [CREATE] Unit tests for amortization math & budget engine
```

---

## 4. Technical Schemas & Data Contracts

### 4.1 Drift Table: `Amortizations`
File: `lib/core/database/tables/amortizations_table.dart`
```dart
import 'package:drift/drift.dart';

class Amortizations extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Foreign key reference to the parent expense
  IntColumn get expenseId => integer().customConstraint('REFERENCES expenses(id) ON DELETE CASCADE')();

  // Total lump-sum amount being spread (e.g. 350.0)
  RealColumn get totalAmount => real()();

  // Total duration in days (e.g. 7)
  IntColumn get durationDays => integer()();

  // Computed straight-line daily cost: totalAmount / durationDays (e.g. 50.0)
  RealColumn get dailyBurden => real()();

  // Normalized midnight start date of amortization
  DateTimeColumn get startDate => dateTime()();

  // Normalized midnight expiration date (startDate + durationDays)
  DateTimeColumn get endDate => dateTime()();
}
```

### 4.2 Combined Schema v4 Updates to `Expenses`
File: `lib/core/database/tables/expenses_table.dart`
In accordance with the Master Plan, schema v4 also adds the two forward-compatible columns:
```dart
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawNote => text().withLength(min: 1, max: 1000)();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get category => text().withDefault(const Constant('Others'))();
  DateTimeColumn get date => dateTime()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  BoolColumn get isPendingAi => boolean().withDefault(const Constant(false))();

  // Schema v4 columns:
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get txnRef => text().nullable()();
}
```

### 4.3 Database Migration Strategy (`schemaVersion => 4`)
File: `lib/core/database/app_database.dart`
```dart
@override
int get schemaVersion => 4; // Upgraded from 3

// Inside migration strategy:
if (from < 4) {
  // 1. Create Amortizations table
  await m.createTable(amortizations);

  // 2. Add Phase 3 columns to Expenses table in same migration
  await m.addColumn(expenses, expenses.source);
  await m.addColumn(expenses, expenses.txnRef);
}
```

### 4.4 DAO Blueprint: `AmortizationDao`
File: `lib/core/database/daos/amortization_dao.dart`
```dart
@DriftAccessor(tables: [Amortizations])
class AmortizationDao extends DatabaseAccessor<AppDatabase> with _$AmortizationDaoMixin {
  AmortizationDao(AppDatabase db) : super(db);

  Stream<List<Amortization>> watchAllAmortizations() => select(amortizations).watch();

  Stream<List<Amortization>> watchActiveAmortizations(DateTime now) {
    final nowMidnight = DateTime(now.year, now.month, now.day);
    return (select(amortizations)
          ..where((tbl) => tbl.startDate.isSmallerOrEqualValue(nowMidnight) & tbl.endDate.isBiggerValue(nowMidnight)))
        .watch();
  }

  Future<int> insertAmortization(AmortizationsCompanion companion) =>
      into(amortizations).insert(companion);

  Future<int> deleteAmortizationByExpenseId(int expenseId) =>
      (delete(amortizations)..where((tbl) => tbl.expenseId.equals(expenseId))).go();

  Future<Amortization?> getAmortizationForExpense(int expenseId) =>
      (select(amortizations)..where((tbl) => tbl.expenseId.equals(expenseId))).getSingleOrNull();
}
```

---

## 5. Budget Engine Mathematical Formula

### The Cycle-Overlap Straight-Line Algorithm
In [`budget_providers.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/data/budget_providers.dart):

```
                       Current Budget Cycle Window
               [ currentCycleStart                  nextCycleStart )
                        │                                  │
Amortization A:         ├─────── startDate ─── endDate ────┤      (Fully inside cycle)
Amortization B:  startDate ───────┤                               (Crosses cycle start)
Amortization C:                                   startDate ───────── endDate (Crosses cycle end)
```

For every amortization $A$ in the database:
1. Determine overlap with the active cycle:
   $$\text{windowStart} = \max(A.\text{startDate}, \text{currentCycleStart})$$
   $$\text{windowEnd} = \min(A.\text{endDate}, \text{nextCycleStart})$$
2. If $\text{windowStart} < \text{windowEnd}$ and $\text{windowStart} \le \text{nowMidnight}$:
   $$\text{effectiveEnd} = \min(\text{windowEnd}, \text{nowMidnight} + 1\text{ day})$$
   $$\text{elapsedDaysInCycle} = \max(0, \text{effectiveEnd}.\text{difference}(\text{windowStart}).\text{inDays})$$
   $$\text{burden}_A = \text{elapsedDaysInCycle} \times A.\text{dailyBurden}$$
3. For regular expenses:
   Exclude any expense whose `id` exists in the set of amortized `expenseId`s.
4. Final calculation:
   $$\text{todaySpendingPower} = \text{allowedBudgetUpToToday} - \text{regularSpentInCycle} - \sum \text{burden}_A$$

---

## 6. Manageable Implementation Chunks

### Chunk 1: Database Blueprints & Migration
* Create `lib/core/database/tables/amortizations_table.dart`.
* Add `source` and `txnRef` columns to `lib/core/database/tables/expenses_table.dart`.
* Create `lib/core/database/daos/amortization_dao.dart`.
* Register `Amortizations` table and `AmortizationDao` in `lib/core/database/app_database.dart`, bump `schemaVersion` to `4`, and write migration step `if (from < 4)`.
* Expose `amortizationDaoProvider` and `allAmortizationsStreamProvider` in `lib/core/database/database_provider.dart`.
* Run `dart run build_runner build --delete-conflicting-outputs` to regenerate Drift models.

### Chunk 2: Budget Engine Integration
* Update `SpendingPower` in `lib/features/expense_entry/data/budget_providers.dart` to include:
  * `totalDailyAmortizedBurden`: Daily rate of currently active amortizations.
  * `activeAmortizationsCount`: Number of currently running amortizations.
* Implement the cycle-overlap algorithm in `budgetEngineProvider`.
* Update `ExpenseDao.deleteExpense(id)` to safely delete any linked amortization record.

### Chunk 3: Expense Entry Logic & UI Form
* Update `ExpenseLogic.addManualExpense()` in `expense_providers.dart`:
  * Accept optional parameter `int? amortizeDays`.
  * If `amortizeDays != null && amortizeDays > 1`: create expense record, then create linked amortization record in an atomic transaction.
* Update `lib/features/expense_entry/presentation/widgets/manual_entry_sheet.dart`:
  * Add switch: **Spread Cost** (`ref.watch(trProvider('spread_cost'))`).
  * Add preset chips: `7 Days`, `14 Days`, `30 Days`, `Custom`.
  * Add live preview banner: shows daily burden (`XX.XX ETB/day`).
  * Ensure all touch targets >= 44x44px.

### Chunk 4: Home Screen Spending Power Badge & Localization
* Update `lib/features/expense_entry/presentation/widgets/budget_header_widget.dart`:
  * When `activeAmortizationsCount > 0`, display a subtle secondary chip/badge:
    `✦ 2 Active Installments • 65 ETB/day`
* Add translation keys across English (`en`), Amharic (`am`), Afaan Oromoo (`om`), and Tigrinya (`ti`) in `lib/core/utils/app_translations.dart`.

### Chunk 5: Verification & Quality Audit
* Create `test/amortization_engine_test.dart` testing:
  * Straight-line daily burden math.
  * Spending power with active amortizations.
  * Cross-cycle boundary calculations.
  * Cleanup on expense deletion.
* Execute `dart format` and `flutter test`.

---

## 7. Review & Hold Gate

Per the [Specs-First Development Protocol](file:///home/philipos/Desktop/Dev/.agents/rules/specs-first.md), this document is held for explicit user review and approval. **No code edits or file modifications will be executed until explicit confirmation is provided.**
