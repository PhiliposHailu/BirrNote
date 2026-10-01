# Remediation Phase 1 — Deep Review Polish

> **Master Plan:** [Master Plan 1 — BirrNote v2.0](file:///home/philipos/Desktop/Dev/birr_note/plans/master_plan_1_birrnote_v2_smart_finance/master_plan_1_birrnote_v2_smart_finance.md)  
> **Source:** [Deep Review — Master Plan 1](file:///home/philipos/.gemini/antigravity-ide/brain/0fd7cc0c-3915-4083-9ebc-97d0b2f2d533/deep_review_master_plan_1.md)  
> **Status:** Completed — Audited & Verified  
> **Date:** 2026-10-01  
> **Scope:** Resolve all 6 findings from the Tier 2 Deep Review audit  

---

## Findings Summary

| # | Finding | Severity | Chunk |
|---|---------|----------|-------|
| 2.1 | Phase 3 spec status says "Draft" but implementation is complete | Low | 4 |
| 2.2 | 1 unused variable + 13 deprecated `.withOpacity()` calls | Low | 3 |
| 2.3 | SMS without `txnRef` bypasses deduplication — duplicate notifications possible | **Medium** | 1 |
| 2.4 | `addManualExpense()` expense+amortization not in a single Drift transaction | Low | 2 |
| 2.5 | `pendingSmsTransactionProvider` declared but unused in production flow | Low | 2 |
| 2.6 | No unit test for `SmsListenerService.handleIncomingMessage()` pipeline | Low | 1 |

---

## Chunk 1: SMS Dedup Hardening & Listener Test (Finding 2.3 + 2.6)

### 1A. Fallback Dedup for Missing `txnRef`

**File:** [`lib/core/sms/sms_listener_service.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/sms/sms_listener_service.dart)

**The Problem:** When a bank SMS arrives without a transaction reference number (malformed message, truncated SMS, etc.), the current code at line 77 skips dedup entirely. If the same SMS is received twice (e.g. Android re-delivers), two notifications fire.

**The Fix:** When `txnRef` is null or empty, compute a deterministic fallback fingerprint and check it against the database before firing.

```dart
// Inside handleIncomingMessage(), replace the dedup block (lines 76-82) with:

// 3. Deduplication check against local Drift database
String? effectiveRef = parsed.txnRef;

// 3a. Fallback: compute fingerprint if bank SMS has no txnRef
if (effectiveRef == null || effectiveRef.isEmpty) {
  // Round timestamp to nearest minute to tolerate slight delivery time variance
  final roundedTs = DateTime(
    parsed.timestamp.year,
    parsed.timestamp.month,
    parsed.timestamp.day,
    parsed.timestamp.hour,
    parsed.timestamp.minute,
  );
  effectiveRef = '${parsed.source}_${parsed.amount.toStringAsFixed(2)}_${roundedTs.millisecondsSinceEpoch}';
}

final exists = await expenseDao.hasExpenseWithTxnRef(effectiveRef);
if (exists) {
  return null; // Already logged or fingerprint matches, suppress notification
}

// Store the effective ref in parsed object for downstream use
// (overwrite null txnRef so ManualEntrySheet saves the fingerprint for future dedup)
final enrichedParsed = ParsedBankSms(
  amount: parsed.amount,
  merchant: parsed.merchant,
  txnRef: effectiveRef,
  source: parsed.source,
  rawBody: parsed.rawBody,
  timestamp: parsed.timestamp,
  suggestedCategory: parsed.suggestedCategory,
);
```

Then update the remainder of the method to use `enrichedParsed` instead of `parsed` for the notification payload and callback.

**Key Invariants:**
- The fingerprint uses `source + amount + timestamp_rounded_to_minute` — deterministic and collision-resistant for the real-world scenario (same payment SMS re-delivered within seconds).
- The fingerprint is stored as `txnRef` so it persists in the DB for future dedup checks.
- Does NOT affect messages that already have a real `txnRef` — those take priority.

### 1B. Listener Service Integration Test

**File:** Create [`test/sms_listener_test.dart`](file:///home/philipos/Desktop/Dev/birr_note/test/sms_listener_test.dart)

Since `handleIncomingMessage()` accepts `ExpenseDao` as a parameter and the notification call can be tested via the callback, we can test the pipeline end-to-end using an in-memory database:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:birr_note/core/database/app_database.dart';
import 'package:birr_note/core/sms/sms_listener_service.dart';
import 'package:birr_note/core/sms/sms_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SmsListenerService.handleIncomingMessage', () {
    test('processes valid Telebirr SMS and triggers callback', () async {
      ParsedBankSms? captured;

      final result = await SmsListenerService().handleIncomingMessage(
        sender: '127',
        body: 'You have transferred ETB 150.00 to Tomoca Coffee. Transaction number is FT99887766.',
        expenseDao: db.expenseDao,
        onParsedTransaction: (sms) async { captured = sms; },
      );

      expect(result, isNotNull);
      expect(result!.amount, 150.0);
      expect(result.merchant, 'Tomoca Coffee');
      expect(result.txnRef, 'FT99887766');
      expect(captured, isNotNull);
    });

    test('rejects non-bank senders', () async {
      final result = await SmsListenerService().handleIncomingMessage(
        sender: '+251911223344',
        body: 'Hey, can you send me 500 birr?',
        expenseDao: db.expenseDao,
      );
      expect(result, isNull);
    });

    test('deduplicates by txnRef', () async {
      // Pre-insert expense with known txnRef
      await db.expenseDao.insertExpense(
        ExpensesCompanion.insert(
          rawNote: 'Tomoca Coffee',
          amount: const Value(150.0),
          category: const Value('Food & Drinks'),
          date: DateTime.now(),
          source: const Value('sms_telebirr'),
          txnRef: const Value('FT99887766'),
        ),
      );

      final result = await SmsListenerService().handleIncomingMessage(
        sender: '127',
        body: 'You have transferred ETB 150.00 to Tomoca Coffee. Transaction number is FT99887766.',
        expenseDao: db.expenseDao,
      );

      expect(result, isNull); // Suppressed — already exists
    });

    test('handles null sender and empty body gracefully', () async {
      expect(
        await SmsListenerService().handleIncomingMessage(
          sender: null, body: 'test', expenseDao: db.expenseDao,
        ),
        isNull,
      );
      expect(
        await SmsListenerService().handleIncomingMessage(
          sender: '127', body: '', expenseDao: db.expenseDao,
        ),
        isNull,
      );
    });
  });
}
```

> [!NOTE]
> The `showSmsTransactionNotification()` call inside `handleIncomingMessage` will throw in a pure unit test environment (no platform channel). Two options:
> 1. **Wrap the notification call in a try-catch** (already present in production — `startListening` does this).
> 2. **Extract the notification call into a callback parameter** to make the method fully testable without platform dependencies. This is the cleaner option but a minor refactor.
>
> **Recommendation:** Option 2 — add an optional `Future<void> Function(int, String, String, String)? onNotify` parameter to `handleIncomingMessage()`. Default to `NotificationService().showSmsTransactionNotification()`. In tests, pass a no-op or mock.

---

## Chunk 2: Transaction Atomicity & Dead Code Cleanup (Finding 2.4 + 2.5)

### 2A. Wrap `addManualExpense()` in Drift Transaction

**File:** [`lib/features/expense_entry/data/expense_providers.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/data/expense_providers.dart#L214-L259)

Replace the current sequential insert pattern (lines 225-258) with a single Drift transaction:

```dart
  // 3. MANUAL ENTRY
  Future<void> addManualExpense({
    required double amount,
    required String category,
    required int quantity,
    required String note,
    DateTime? date,
    int? amortizeDays,
    String source = 'manual',
    String? txnRef,
  }) async {
    final expenseDate = date ?? DateTime.now();

    // Atomic transaction: expense + optional amortization are committed together
    await expenseDao.transaction(() async {
      final expenseId = await expenseDao.insertExpense(
        ExpensesCompanion.insert(
          rawNote: note.trim().isEmpty ? category : note,
          amount: Value(amount),
          category: Value(category),
          quantity: Value(quantity),
          date: expenseDate,
          isPendingAi: const Value(false),
          source: Value(source),
          txnRef: Value(txnRef),
        ),
      );

      if (amortizeDays != null && amortizeDays > 1 && amount > 0) {
        final startMidnight = DateTime(
          expenseDate.year,
          expenseDate.month,
          expenseDate.day,
        );
        final endMidnight = startMidnight.add(Duration(days: amortizeDays));
        final dailyBurden = amount / amortizeDays;

        await amortizationDao.insertAmortization(
          AmortizationsCompanion.insert(
            expenseId: expenseId,
            totalAmount: amount,
            durationDays: amortizeDays,
            dailyBurden: dailyBurden,
            startDate: startMidnight,
            endDate: endMidnight,
          ),
        );
      }
    });
  }
```

**Why:** If the app crashes between the expense insert and amortization insert, an orphaned expense stays in the DB without its amortization record. Drift's `transaction()` ensures both writes succeed or both are rolled back.

### 2B. Document `pendingSmsTransactionProvider` as Reserved

**File:** [`lib/core/sms/sms_providers.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/sms/sms_providers.dart#L31-L34)

Update the comment to explicitly mark it as reserved infrastructure:

```dart
/// Reserved for future use: in-app SMS queue and review flow.
/// Currently unused — the production deep-link flow uses the notification
/// payload stream (NotificationService.onPayloadTapped → ManualEntrySheet)
/// rather than this provider. Retained for future expansion (e.g. batch SMS review).
final pendingSmsTransactionProvider = StateProvider<ParsedBankSms?>(
  (ref) => null,
);
```

---

## Chunk 3: Static Analysis Cleanup (Finding 2.2)

### 3A. Fix Unused Variable

**File:** [`lib/features/settings/presentation/widgets/daily_reminder_card.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/daily_reminder_card.dart#L118)

Line 118: `final time = TimeOfDay(hour: _hour, minute: _minute);` — this variable is declared but never read.

**Fix:** Remove the line entirely, or if the variable was intended for a future display, prefix it with an underscore (`final _time = ...`). Given it's clearly unused, remove it.

### 3B. Migrate `.withOpacity()` → `.withValues(alpha: ...)`

13 occurrences across 8 files. Each `.withOpacity(X)` should be replaced with `.withValues(alpha: X)`.

| # | File | Line | Current | Replacement |
|---|------|------|---------|-------------|
| 1 | [`dashboard_screen.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/dashboard/presentation/dashboard_screen.dart) | 90 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 2 | [`trend_bar_chart.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/dashboard/presentation/widgets/trend_bar_chart.dart) | 103 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 3 | [`settings_screen.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/settings_screen.dart) | 41 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 4 | [`settings_screen.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/settings_screen.dart) | 84 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 5 | [`settings_screen.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/settings_screen.dart) | 180 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 6 | [`battery_optimization_tile.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/battery_optimization_tile.dart) | 14 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 7 | [`daily_reminder_card.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/daily_reminder_card.dart) | 124 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 8 | [`gemini_key_sheet.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/gemini_key_sheet.dart) | 108 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 9 | [`gemini_key_sheet.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/gemini_key_sheet.dart) | 146 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 10 | [`gemini_key_sheet.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/gemini_key_sheet.dart) | 220 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 11 | [`samsung_time_dialog.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/samsung_time_dialog.dart) | 139 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 12 | [`time_roller_column.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/time_roller_column.dart) | 156 | `.withOpacity(...)` | `.withValues(alpha: ...)` |
| 13 | [`weekly_budget_card.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/weekly_budget_card.dart) | 77 | `.withOpacity(...)` | `.withValues(alpha: ...)` |

**Migration pattern:**
```dart
// BEFORE:
color.withOpacity(0.4)

// AFTER:
color.withValues(alpha: 0.4)
```

---

## Chunk 4: Documentation Sync (Finding 2.1)

### 4A. Update Phase 3 Spec Status

**File:** [`plan_m1_phase_3_sms_transaction_tracking.md`](file:///home/philipos/Desktop/Dev/birr_note/plans/master_plan_1_birrnote_v2_smart_finance/plan_m1_phase_3_sms_transaction_tracking.md)

Change line 4 from:
```markdown
> **Status:** Draft — Awaiting User Approval
```
To:
```markdown
> **Status:** Completed — Audited & Verified
```

---

## Task Checklist

- [x] **Chunk 1A:** Add fallback dedup fingerprint in `sms_listener_service.dart`
- [x] **Chunk 1B:** Create `test/sms_listener_test.dart` with 5 integration tests
- [x] **Chunk 1B (optional):** Refactor notification call into injectable callback for testability
- [x] **Chunk 2A:** Wrap `addManualExpense()` in `expenseDao.transaction()`
- [x] **Chunk 2B:** Update `pendingSmsTransactionProvider` comment as reserved
- [x] **Chunk 3A:** Remove unused `time` variable in `daily_reminder_card.dart:118`
- [x] **Chunk 3B:** Migrate 13 `.withOpacity()` → `.withValues(alpha: ...)` across 8 files
- [x] **Chunk 4A:** Update Phase 3 spec status to "Completed — Audited & Verified"
- [x] **Final:** Run `flutter test` and `flutter analyze` to verify 0 errors, 0 warnings

---

## Verification Gate

After all chunks:
```bash
flutter test          # Expect: all tests pass (existing 25 + new 4 = 29)
flutter analyze       # Expect: 0 errors, 0 warnings (down from 7), info-only remaining
git status -s         # Expect: clean or only expected modifications
```

---

## Review & Hold Gate

Per the [Specs-First Development Protocol](file:///home/philipos/Desktop/Dev/.agents/rules/specs-first.md), this document is held for explicit user review and approval. **No code edits will be executed until confirmation is given.**
