# Master Plan 1 — BirrNote v2.0: Smart Finance Engine

> **Status:** Draft — Awaiting approval
> **Author:** Antigravity × Philipos
> **Date:** 2026-09-27
> **Scope:** Three new features, all on-device, zero server cost

---

## Executive Summary

Three features that transform BirrNote from a daily expense logger into a **smart personal finance system**, while keeping everything free and local:

| Phase | Feature | Core Problem it Solves |
|-------|---------|----------------------|
| **Phase 1** | Dynamic Gemini Model Picker | Models get deprecated/added frequently; hardcoded `gemini-3.1-flash-lite` will inevitably break |
| **Phase 2** | Expense Amortization Engine | A single 350 ETB purchase tanks your daily budget to -250 ETB, making the tracker useless for days |
| **Phase 3** | SMS-Based Transaction Tracking | CBE and Telebirr payments are invisible to the app — you must manually re-enter every digital payment |

---

## Current Codebase Snapshot (Pre-Plan)

### Database: Schema Version 3
```
┌──────────────────────────────────────────────────────┐
│ Expenses                                             │
│ ─────────                                            │
│ id (PK), rawNote, amount, category, date,            │
│ quantity, isPendingAi                                │
├──────────────────────────────────────────────────────┤
│ CategoryOptions                                      │
│ ───────────────                                      │
│ id (PK), name (UNIQUE), orderIndex                   │
├──────────────────────────────────────────────────────┤
│ Budgets                                              │
│ ───────                                              │
│ id (PK), limitAmount, period, startDate              │
└──────────────────────────────────────────────────────┘
```

### Key Files
| File | Role |
|------|------|
| [`ai_service.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/network/ai_service.dart) | Gemini API calls (hardcoded model: `gemini-3.1-flash-lite`) |
| [`api_key_provider.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/network/api_key_provider.dart) | Secure storage for API key + AI toggle |
| [`gemini_key_sheet.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/gemini_key_sheet.dart) | Settings bottom sheet for API key entry |
| [`settings_screen.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/settings_screen.dart) | Main settings page |
| [`budget_providers.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/data/budget_providers.dart) | Budget engine — computes `todaySpendingPower` |
| [`expense_providers.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/data/expense_providers.dart) | Expense CRUD logic + offline queue |
| [`manual_entry_sheet.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/presentation/widgets/manual_entry_sheet.dart) | Manual expense form |
| [`budget_header_widget.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/presentation/widgets/budget_header_widget.dart) | Home screen spending power display |
| [`app_database.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/database/app_database.dart) | Drift DB setup, migrations, seed data |
| [`budgets_table.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/database/tables/budgets_table.dart) | Budget table schema |
| [`expenses_table.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/database/tables/expenses_table.dart) | Expenses table schema |
| [`expense_dao.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/database/daos/expense_dao.dart) | Expense DB queries |
| [`budget_dao.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/database/daos/budget_dao.dart) | Budget DB queries |
| [`pubspec.yaml`](file:///home/philipos/Desktop/Dev/birr_note/pubspec.yaml) | Dependencies |
| [`app_translations.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/utils/app_translations.dart) | 4-language translation keys |

---

## Phase 1: Dynamic Gemini Model Picker

> **Goal:** Replace the two hardcoded `'gemini-3.1-flash-lite'` strings with a runtime model selector. Default to `gemini-3.8-flash`. When Google deprecates or adds models, the list updates automatically.

### How It Works

```
User saves API Key
       │
       ▼
App calls GET /v1beta/models?key=KEY
       │
       ▼
Filter: only models where
  supportedGenerationMethods contains "generateContent"
       │
       ▼
Cache filtered list in SharedPreferences (offline fallback)
       │
       ▼
Show dropdown in Settings → User picks model
       │
       ▼
ai_service.dart reads selected model from provider
```

### API Response Shape (from Google)
```json
{
  "models": [
    {
      "name": "models/gemini-3.8-flash",
      "displayName": "Gemini 3.8 Flash",
      "supportedGenerationMethods": ["generateContent", "countTokens"]
    },
    {
      "name": "models/text-embedding-004",
      "displayName": "Text Embedding 004",
      "supportedGenerationMethods": ["embedContent"]
    }
  ]
}
```
→ We only show models containing `"generateContent"`.
→ `name` field returns `"models/gemini-3.8-flash"` — we strip the `"models/"` prefix to get `"gemini-3.8-flash"`.

### Files to Create / Modify

| Action | File | What Changes |
|--------|------|-------------|
| **CREATE** | `lib/core/network/model_provider.dart` | New file: `AvailableModelsNotifier` (fetches + caches model list), `SelectedModelNotifier` (reads/writes selected model from SharedPrefs), Riverpod providers |
| **MODIFY** | `lib/core/network/ai_service.dart` | Remove hardcoded `'gemini-3.1-flash-lite'` from both `parseNoteToExpenses` and `askAdvisor`. Accept model name as constructor parameter. |
| **MODIFY** | `lib/features/settings/presentation/widgets/gemini_key_sheet.dart` | Add a `DropdownButton` showing cached models. Trigger model list refresh when key is saved. |
| **MODIFY** | `lib/core/network/api_key_provider.dart` | After `saveKey()`, trigger model list fetch. |
| **MODIFY** | `pubspec.yaml` | Add `http: ^1.4.0` dependency. |

### Data Contracts

#### `model_provider.dart` — Core Types
```dart
// Cached model representation
class GeminiModelInfo {
  final String id;          // e.g. "gemini-3.8-flash"
  final String displayName; // e.g. "Gemini 3.8 Flash"
  GeminiModelInfo({required this.id, required this.displayName});
}

// SharedPreferences keys:
//   'cached_models'   → JSON-encoded List<GeminiModelInfo>
//   'selected_model'  → String model ID (default: 'gemini-3.8-flash')

// Riverpod providers:
//   availableModelsProvider → AsyncNotifierProvider<..., List<GeminiModelInfo>>
//   selectedModelProvider   → StateNotifierProvider<..., String>
```

#### `ai_service.dart` — Updated Constructor
```dart
class AiService {
  final String? apiKey;
  final String modelName;  // NEW: injected from selectedModelProvider

  AiService(this.apiKey, {this.modelName = 'gemini-3.8-flash'});
  // ...
  // Both methods use: model: modelName
}
```

### Task Checklist — Phase 1
- [x] Add `http: ^1.4.0` to `pubspec.yaml` and run `flutter pub get`
- [x] Create `lib/core/network/model_provider.dart` with fetch, cache, and provider logic
- [x] Modify `AiService` to accept `modelName` parameter, remove hardcoded strings
- [x] Update `aiServiceProvider` to inject `selectedModelProvider` value
- [x] Add model dropdown UI to `gemini_key_sheet.dart`
- [x] Add translation keys for model picker labels (4 languages)
- [x] Test: verify model list loads, persists offline, and switches correctly

---

## Phase 2: Expense Amortization Engine ("Spread the Burden")

> **Goal:** When logging an expensive purchase, optionally distribute its impact across N days so it doesn't nuke your daily spending power.

### The Problem (Today)
```
Daily budget limit:   100 ETB
User buys:            350 ETB telecom package

Today's Spending Power = 100 - 350 = -250 ETB  ← USELESS for the rest of the week
```

### The Solution (After)
```
User buys 350 ETB, toggles "Spread over 7 days"

Daily Burden = 350 / 7 = 50 ETB/day

Day 1: Spending Power = 100 - 50 = 50 ETB  ← Still usable!
Day 2: Spending Power = 100 - 50 = 50 ETB
...
Day 7: Spending Power = 100 - 50 = 50 ETB  (last day of amortization)
Day 8: Spending Power = 100 - 0  = 100 ETB ← Burden expired, back to normal
```

### How It Works — Data Model

#### New DB Table: `Amortizations`
```dart
class Amortizations extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Links to the original expense that is being spread
  IntColumn get expenseId => integer()();

  // The total amount being amortized (e.g. 350.0)
  RealColumn get totalAmount => real()();

  // Duration in days (e.g. 7)
  IntColumn get durationDays => integer()();

  // The computed daily burden (totalAmount / durationDays = 50.0)
  RealColumn get dailyBurden => real()();

  // When the amortization window starts (midnight of creation day)
  DateTimeColumn get startDate => dateTime()();

  // When it expires (startDate + durationDays)
  DateTimeColumn get endDate => dateTime()();
}
```

#### How the Budget Engine Changes

Current formula in [`budget_providers.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/data/budget_providers.dart#L122-L123):
```dart
// TODAY:
final todaySpendingPower = allowedBudgetUpToToday - actualSpentInCurrentCycle;
```

New formula:
```dart
// AFTER:
// 1. When calculating actualSpentInCurrentCycle, EXCLUDE amortized expenses
//    (they are not counted as lump-sum spending)
// 2. Instead, sum up the dailyBurden of all ACTIVE amortizations
//    (where today is between startDate and endDate)
// 3. Multiply each dailyBurden by the number of elapsed days in this budget cycle
//    (or the overlap between the amortization window and the budget cycle)

final amortizedBurdenToday = sum of (dailyBurden × daysElapsedInCycle) for each active amortization;
final todaySpendingPower = allowedBudgetUpToToday - regularSpentInCycle - amortizedBurdenToday;
```

> [!IMPORTANT]
> **Key invariant:** The original expense amount (350 ETB) is recorded in the `expenses` table for historical accuracy and chart correctness. But the `budget_providers.dart` engine treats it differently — instead of counting 350 as a single-day hit, it spreads 50/day across the amortization window.

### Files to Create / Modify

| Action | File | What Changes |
|--------|------|-------------|
| **CREATE** | `lib/core/database/tables/amortizations_table.dart` | New Drift table definition |
| **CREATE** | `lib/core/database/daos/amortization_dao.dart` | CRUD + `watchActiveAmortizations()` stream |
| **MODIFY** | `lib/core/database/app_database.dart` | Register new table + DAO, bump schema to v4, add migration |
| **MODIFY** | `lib/features/expense_entry/data/budget_providers.dart` | Integrate amortization burden into spending power calculation |
| **MODIFY** | `lib/features/expense_entry/data/expense_providers.dart` | `ExpenseLogic.addManualExpense()` accepts optional amortization params; creates linked amortization record |
| **MODIFY** | `lib/features/expense_entry/presentation/widgets/manual_entry_sheet.dart` | Add "Spread cost over time" toggle + duration picker (quick presets: 7, 14, 30 days + custom) |
| **MODIFY** | `lib/features/expense_entry/presentation/widgets/budget_header_widget.dart` | Show active amortizations indicator (e.g. small "2 active installments" label) |
| **MODIFY** | `lib/core/utils/app_translations.dart` | Add translation keys for amortization UI (4 languages) |

### User Flow
```
1. User taps "+" (Manual Entry) or types in chat
2. Enters amount: 350
3. Enters category: Bills
4. NEW: Sees toggle → [☐ Spread cost over time]
5. User toggles ON → Duration picker appears:
   [7 days] [14 days] [30 days] [Custom...]
6. Taps "7 days" → Preview shows: "50 ETB/day for 7 days"
7. Taps Save →
   a. Expense record created (amount=350, category=Bills)
   b. Amortization record created (expenseId=X, totalAmount=350, durationDays=7, dailyBurden=50)
8. Budget engine immediately reflects:
   Today's Spending Power: 100 - 50 = 50 ETB (instead of -250)
```

### Task Checklist — Phase 2
- [ ] Create `amortizations_table.dart` with schema above
- [ ] Create `amortization_dao.dart` with CRUD + active stream query
- [ ] Register table and DAO in `app_database.dart`, bump to schema v4
- [ ] Write migration: `if (from < 4) await m.createTable(amortizations);`
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`
- [ ] Modify `ExpenseLogic` to accept optional amortization parameters
- [ ] Modify `budget_providers.dart` to exclude amortized expenses from lump-sum and add daily burden
- [ ] Add "Spread cost" toggle + duration picker to `manual_entry_sheet.dart`
- [ ] Add active amortizations indicator to `budget_header_widget.dart`
- [ ] Add translation keys (4 languages)
- [ ] Test: verify spending power math, amortization expiry, edge cases (budget cycle boundary overlaps)

---

## Phase 3: SMS-Based Transaction Tracking (CBE & Telebirr)

> **Goal:** Automatically detect CBE and Telebirr payment SMS alerts in the background and offer one-tap expense logging.

### How It Works

```
┌─────────────────────────┐
│ User pays via Telebirr  │
│ or CBE Mobile Banking   │
└───────────┬─────────────┘
            │ Android SMS arrives
            ▼
┌─────────────────────────┐
│ BroadcastReceiver /     │  (easy_sms_receiver package)
│ SMS Listener Service    │
└───────────┬─────────────┘
            │ Filter: sender matches Telebirr/CBE
            ▼
┌─────────────────────────┐
│ Regex Parser            │  Extract: amount, merchant, txnRef
│ (sms_parser.dart)       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Dedup Check             │  hash(source + amount + date) → skip if exists
└───────────┬─────────────┘
            │ New transaction
            ▼
┌─────────────────────────┐
│ Local Push Notification │  "Detected ✦ ETB 150 to Tomoca. Tap to save."
└───────────┬─────────────┘
            │ User taps notification
            ▼
┌─────────────────────────┐
│ Pre-filled expense form │  → Amount: 150, Note: "Tomoca", Source: sms_telebirr
│ (manual_entry_sheet)    │  → User confirms or edits category, then saves
└─────────────────────────┘
```

### SMS Sender ID Mapping (Ethiopian Banks)
| Bank | Known Sender IDs | SMS Format Examples |
|------|-----------------|-------------------|
| **Telebirr** | `127`, `telebirr`, `Ethio telecom` | `"You have transferred ETB 150.00 to Tomoca Coffee. Transaction number is FT12345678."` |
| **CBE** | `898`, `CBE`, `CBE Birr` | `"Dear customer, your account ...1234 has been debited with ETB 250.00 on 27/09/2026."` |

### Regex Patterns
```dart
// Telebirr: Extract amount and merchant
r'ETB\s*([\d,]+\.?\d*)\s*to\s*([^.]+)'

// CBE: Extract amount (merchant rarely included in CBE SMS)
r'(?:debited|deducted)\s*(?:with\s*)?ETB\s*([\d,]+\.?\d*)'

// Transaction reference (both)
r'(?:Transaction|Txn|Ref)\s*(?:number|no|#|:)?\s*(?:is\s*)?([A-Z0-9]+)'
```

### Database Changes

#### Modify `expenses_table.dart` — Add 2 columns:
```dart
class Expenses extends Table {
  // ... existing columns ...

  // NEW: Track where the expense came from
  // Values: 'manual' (default), 'sms_telebirr', 'sms_cbe', 'ai_chat'
  TextColumn get source => text().withDefault(const Constant('manual'))();

  // NEW: Bank transaction reference for deduplication (nullable)
  TextColumn get txnRef => text().nullable()();
}
```

#### Migration (part of schema v4 in Phase 2):
```dart
if (from < 4) {
  await m.createTable(amortizations);  // Phase 2
  await m.addColumn(expenses, expenses.source);  // Phase 3
  await m.addColumn(expenses, expenses.txnRef);  // Phase 3
}
```

### Files to Create / Modify

| Action | File | What Changes |
|--------|------|-------------|
| **CREATE** | `lib/core/sms/sms_parser.dart` | Regex extraction: amount, merchant, txnRef for Telebirr and CBE formats |
| **CREATE** | `lib/core/sms/sms_listener_service.dart` | Background SMS listener setup, sender filtering, notification trigger |
| **CREATE** | `lib/core/sms/sms_providers.dart` | Riverpod providers: SMS toggle state, parsed transaction state |
| **MODIFY** | `lib/core/database/tables/expenses_table.dart` | Add `source` and `txnRef` columns |
| **MODIFY** | `lib/core/database/app_database.dart` | Migration for new columns (combined with Phase 2 migration) |
| **MODIFY** | `lib/core/database/daos/expense_dao.dart` | Add `checkDuplicate(txnRef)` query method |
| **MODIFY** | `lib/features/expense_entry/data/expense_providers.dart` | Add `addSmsExpense()` method in `ExpenseLogic` |
| **MODIFY** | `lib/features/settings/presentation/settings_screen.dart` | Add "Auto-track bank SMS" toggle in Security & Cloud section |
| **MODIFY** | `lib/core/utils/app_translations.dart` | Add translation keys for SMS feature (4 languages) |
| **MODIFY** | `pubspec.yaml` | Add `easy_sms_receiver` dependency |
| **MODIFY** | `android/app/src/main/AndroidManifest.xml` | Add `RECEIVE_SMS` permission |

### User Flow (First-Time Setup)
```
1. Settings → "Auto-track bank SMS" toggle → ON
2. Android permission dialog: "Allow BirrNote to read SMS?" → Allow
3. Done. From now on, every Telebirr/CBE payment triggers a notification.
4. User taps notification → pre-filled form → confirm → saved.
```

### Task Checklist — Phase 3
- [ ] Add `easy_sms_receiver` to `pubspec.yaml`
- [ ] Add `RECEIVE_SMS` permission to `AndroidManifest.xml`
- [ ] Create `sms_parser.dart` with regex patterns for Telebirr + CBE
- [ ] Create `sms_listener_service.dart` with sender filtering logic
- [ ] Create `sms_providers.dart` with SMS toggle persistence
- [ ] Add `source` and `txnRef` columns to `expenses_table.dart`
- [ ] Add dedup query to `expense_dao.dart`
- [ ] Add `addSmsExpense()` to `ExpenseLogic`
- [ ] Add SMS toggle to settings screen
- [ ] Wire notification tap → pre-filled `ManualEntrySheet`
- [ ] Add translation keys (4 languages)
- [ ] Test: mock SMS parsing, dedup logic, notification flow

---

## Combined Database Migration (Schema v3 → v4)

All DB changes from Phase 2 and Phase 3 are bundled into a **single migration** to keep it clean:

```dart
@override
int get schemaVersion => 4;  // Was 3

// In migration:
if (from < 4) {
  // Phase 2: Amortization table
  await m.createTable(amortizations);

  // Phase 3: SMS tracking columns on expenses
  await m.addColumn(expenses, expenses.source);
  await m.addColumn(expenses, expenses.txnRef);
}
```

After migration, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Dependency Changes Summary

```yaml
# pubspec.yaml additions:
dependencies:
  http: ^1.4.0                  # Phase 1: REST call to list models
  easy_sms_receiver: ^0.0.5     # Phase 3: Background SMS listening
```

---

## Phasing & Execution Order

```
Phase 1 (Model Picker)  →  Phase 2 (Amortization)  →  Phase 3 (SMS Tracking)
      │                          │                           │
   No DB changes            DB schema v4 created        Columns added to
   Quick win                Core budget logic            same v4 migration
   ~1 session               ~2 sessions                 ~2 sessions
```

> [!NOTE]
> **Why this order:**
> - Phase 1 is standalone (no DB changes, no new tables). Quick confidence-building win.
> - Phase 2 creates the schema v4 migration. Phase 3 piggybacks on the same migration.
> - Phase 3 depends on the `flutter_local_notifications` infrastructure you already have, plus the new DB columns from the shared migration.

---

## Resume-Grade Architecture Summary

After completing all three phases, BirrNote demonstrates:

| Concept | Implementation | Where Interviewers See It |
|---------|---------------|--------------------------|
| **Event-Driven Pipeline** | SMS → Parser → Dedup → Notification → DB | Phase 3 |
| **Runtime API Discovery** | Model registry query + offline caching | Phase 1 |
| **Financial Amortization** | Straight-line depreciation with budget integration | Phase 2 |
| **Offline-First Architecture** | Optimistic writes, reconciliation queue, cached model list | All phases |
| **Schema Evolution** | Drift migrations with backward compatibility | Phase 2+3 |
| **Multi-Calendar Math** | Ethiopian 13-month cycle boundary calculations | Existing + Phase 2 |
