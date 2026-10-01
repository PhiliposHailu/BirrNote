# Phase 3: SMS-Based Transaction Tracking (CBE & Telebirr)

> **Master Plan:** [`master_plan_1_birrnote_v2_smart_finance.md`](file:///home/philipos/Desktop/Dev/birr_note/plans/master_plan_1_birrnote_v2_smart_finance/master_plan_1_birrnote_v2_smart_finance.md)  
> **Status:** Completed — Audited & Verified  
> **Author:** Antigravity × Philipos  
> **Date:** 2026-09-29  
> **Scope:** Automatic background detection of Telebirr and CBE payment confirmation SMS alerts with 1-tap pre-filled expense logging, on-device parsing, strict deduplication, and zero cloud dependencies.

---

## 1. Executive Summary & Problem Definition

### The Friction in Digital Payments
In Ethiopia, over 80% of urban micro-transactions occur through **Telebirr** (Ethio telecom) and **CBE Birr / CBE Mobile Banking** (Commercial Bank of Ethiopia). Currently, BirrNote requires users to open the app and manually type every coffee, taxi ride, and grocery payment—even though the phone already received an official SMS confirming the exact amount, merchant, and reference code.

### The Solution: Zero-Friction 1-Tap Capture
When enabled by the user:
1. BirrNote listens for incoming SMS from verified sender IDs (`127`, `telebirr`, `898`, `CBE`).
2. An on-device deterministic regex engine parses amount, merchant/counterparty, and transaction reference (`txnRef`).
3. An idempotency check queries the local Drift database to verify the `txnRef` has not already been logged.
4. A rich local notification prompts: *"✦ Detected 150 ETB to Tomoca. Tap to save."*
5. Tapping the notification opens BirrNote with a pre-filled `ManualEntrySheet`, selecting the most likely category and preserving the transaction reference.

---

## 2. HCI & UI/UX Design Invariants

Following our core platform guidelines:

### A. Trust, Transparency & Financial Invariants
- **100% On-Device Privacy Invariant:** SMS messages are never uploaded to any remote server or passed to external AI models. All parsing is deterministic and local.
- **Explicit Opt-In & Explainable Permissions:** A dedicated toggle in Settings explains *why* the permission is requested, *which* sender IDs are read, and guarantees that non-banking SMS are ignored.
- **Masked Data Integrity:** Account numbers (e.g. `...1234`) are truncated or omitted from user-facing notes to maintain privacy.

### B. Cognitive Load Reduction & 1-Tap Flow
- **Pre-filled Bottom Sheet:** Rather than silently writing unconfirmed expenses into the database, BirrNote shows a pre-filled confirmation sheet where the user only needs to verify the category and press "Save".
- **Smart Category Heuristics:** Known Ethiopian merchant keywords automatically pre-select categories (e.g., "Cafe", "Coffee", "Restaurant" $\to$ *Food & Dining*; "Ride", "Feres" $\to$ *Transport*).

### C. Error Prevention & Idempotency
- **Strict Deduplication:** Every bank SMS contains a unique transaction number (e.g. `FT2409...` or `TXN...`). If this `txnRef` already exists in the `expenses` table, the notification is suppressed.
- **Non-Destructive Dismissal:** Dismissing the notification does nothing harmful—the user can still log manually or enter via AI voice/text note.

### D. Mobile Ergonomics & Fitts's Law
- **Thumb-Zone Action:** The notification tap presents a bottom sheet with high-contrast primary CTA ("Confirm & Save") occupying a standard 48px height target within natural thumb reach.

---

## 3. Architecture & Data Flow

```
                      INCOMING ANDROID SMS
                               │
                               ▼
               ┌───────────────────────────────┐
               │   easy_sms_receiver Listener  │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │    Sender Filtering Gate      │
               │   Is Telebirr or CBE ID?      │
               └───────┬───────────────┬───────┘
                      NO              YES
                       │               ▼
                   [IGNORE]    ┌───────────────────────────────┐
                               │       SmsParser Engine        │
                               │  Extract: Amount, Note, Ref   │
                               └───────────────┬───────────────┘
                                               │
                                               ▼
                               ┌───────────────────────────────┐
                               │   Drift Idempotency Check     │
                               │  expenseDao.hasTxnRef(ref)?   │
                               └───────┬───────────────┬───────┘
                                      YES              NO
                                       │               ▼
                                   [DROP]      ┌───────────────────────────────┐
                                               │  NotificationService Trigger  │
                                               │  "✦ Detected 150 ETB to ..."  │
                                               └───────────────┬───────────────┘
                                                               │ User Taps
                                                               ▼
                                               ┌───────────────────────────────┐
                                               │   ManualEntrySheet Pre-fill   │
                                               │   Review Category & Confirm   │
                                               └───────────────────────────────┘
```

---

## 4. Technical Specifications & Regex Contracts

### A. Ethiopian Bank Sender IDs
```dart
const Set<String> kTelebirrSenders = {'127', 'telebirr', 'ethio telecom', 'ethiotelecom'};
const Set<String> kCbeSenders = {'898', 'cbe', 'cbe birr', 'cbebirr'};
```

### B. Regex Parsing Rules

#### 1. Telebirr SMS Formats
- **Format A (Transfer to Merchant/Person):**  
  `"You have transferred ETB 150.00 to Tomoca Coffee. Transaction number is FT12345678."`
- **Format B (Merchant Pay):**  
  `"You have paid ETB 450.50 to TOTAL ETHIOPIA. Transaction ID: MP98765432."`
- **Format C (Cash Out / ATM):**  
  `"You have withdrawn ETB 1000.00. Transaction number is CW55667788."`

**Extraction Regex:**
- Amount: `r'(?:transferred|paid|withdrawn|debited)\s+(?:ETB|Birr)\s*([\d,]+\.?\d*)'i`
- Merchant: `r'(?:to|at)\s+([^.]+?)(?:\.\s*Transaction|\s*Txn|\s*Ref|$)'i`
- TxnRef: `r'(?:Transaction|Txn|Ref)(?:\s*(?:number|no|id|#|:))?\s*(?:is\s*)?([A-Z0-9]+)'i`

#### 2. CBE (Commercial Bank of Ethiopia) SMS Formats
- **Format A (Direct Account Debit):**  
  `"Dear customer, your account 1000****1234 has been debited with ETB 250.00 on 28/09/2026. Txn ID: FT24270XXX."`
- **Format B (CBE Birr Wallet):**  
  `"You have transferred ETB 350.00 to 0911223344 (Abebe Kebede). Ref: CB891234."`

**Extraction Regex:**
- Amount: `r'(?:debited\s+with|transferred|paid)\s+(?:ETB|Birr)\s*([\d,]+\.?\d*)'i`
- Merchant: `r'to\s+([^\.]+?)(?:\.\s*Ref|\s*Txn|\s*on\s+\d|$)'i` (falls back to `"CBE Transfer"` if not present)
- TxnRef: `r'(?:Txn|Ref|Transaction)(?:\s*(?:ID|Id|no|#|:))?\s*(?:is\s*)?([A-Z0-9]+)'i`

---

## 5. Schema & Database State

In Phase 2, the schema was already upgraded to **v4** and prepared with:
```dart
// lib/core/database/tables/expenses_table.dart
TextColumn get source => text().withDefault(const Constant('manual'))(); // 'manual', 'sms_telebirr', 'sms_cbe'
TextColumn get txnRef => text().nullable()(); // Unique bank transaction ID
```

In Phase 3, we add:
```dart
// In lib/core/database/daos/expense_dao.dart:
Future<bool> hasExpenseWithTxnRef(String txnRef) async {
  final query = select(expenses)..where((tbl) => tbl.txnRef.equals(txnRef));
  final match = await query.getSingleOrNull();
  return match != null;
}
```

---

## 6. Implementation Chunks

### Chunk 1: Dependencies, Permissions & SMS Parser
- Add `easy_sms_receiver: ^0.0.2` to [`pubspec.yaml`](file:///home/philipos/Desktop/Dev/birr_note/pubspec.yaml).
- Add `<uses-permission android:name="android.permission.RECEIVE_SMS"/>` to [`android/app/src/main/AndroidManifest.xml`](file:///home/philipos/Desktop/Dev/birr_note/android/app/src/main/AndroidManifest.xml).
- Create [`lib/core/sms/sms_models.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/sms/sms_models.dart):
  - `ParsedBankSms` entity with fields: `amount`, `merchant`, `txnRef`, `source`, `rawBody`, `timestamp`.
- Create [`lib/core/sms/sms_parser.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/sms/sms_parser.dart):
  - Pure, deterministic parsing functions with unit test coverage for Telebirr and CBE variations.
  - Smart category suggester based on merchant keywords.

### Chunk 2: DAO Deduplication & Expense Logic Integration
- Update [`lib/core/database/daos/expense_dao.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/database/daos/expense_dao.dart):
  - Add `hasExpenseWithTxnRef(String txnRef)`.
  - Add `getExpenseByTxnRef(String txnRef)`.
- Update [`lib/features/expense_entry/data/expense_providers.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/data/expense_providers.dart):
  - Add `addSmsExpense({required double amount, required String category, String? note, required String source, required String txnRef})`.

### Chunk 3: Notification Payload & Deep-Linking Flow
- Update [`lib/core/notifications/notification_service.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/notifications/notification_service.dart):
  - Configure `onDidReceiveNotificationResponse` callback.
  - Add `showSmsTransactionNotification({required int id, required String title, required String body, required String payload})`.
- Create [`lib/core/sms/sms_providers.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/sms/sms_providers.dart):
  - `pendingSmsTransactionProvider` (`StateProvider<ParsedBankSms?>`): Holds pre-fill transaction data when notification is tapped.
  - `smsTrackingEnabledProvider` (`StateNotifierProvider<SmsTrackingNotifier, bool>`): Persisted in `SharedPreferences`.

### Chunk 4: Background Listener & Settings UI
- Create [`lib/core/sms/sms_listener_service.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/sms/sms_listener_service.dart):
  - Starts listening when enabled.
  - Verifies sender whitelist, runs parser, verifies deduplication with `expenseDao`, and posts local notification.
- Update [`lib/features/settings/presentation/settings_screen.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/settings_screen.dart):
  - Add "Auto-Track Bank SMS" switch tile under Preferences / Security.
  - Add informational dialog detailing Telebirr & CBE support and the on-device privacy guarantee.
  - Wire permission request via `permission_handler`.
- Update [`lib/features/expense_entry/presentation/widgets/manual_entry_sheet.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/expense_entry/presentation/widgets/manual_entry_sheet.dart):
  - Accept optional `ParsedBankSms? initialSms` to automatically pre-fill amount, merchant note, and transaction badge.
- Update [`lib/core/utils/app_translations.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/utils/app_translations.dart):
  - Add keys across English, Amharic, Afaan Oromoo, and Tigrinya:
    `auto_track_sms`, `auto_track_sms_desc`, `sms_permission_needed`, `sms_privacy_note`, `detected_payment`, `tap_to_log`.

### Chunk 5: Testing & Verification
- Create [`test/sms_parser_test.dart`](file:///home/philipos/Desktop/Dev/birr_note/test/sms_parser_test.dart):
  - Test Telebirr transfer, merchant pay, and cash out formats.
  - Test CBE account debit and CBE Birr wallet transfers.
  - Test ignore non-banking SMS (spam, OTPs, personal messages).
  - Test deduplication logic.
- Execute `flutter test` and `dart format`.

---

## 7. Review & Hold Gate

> [!IMPORTANT]
> **Spec-First Invariant:** In accordance with platform methodologies, no implementation code will be written until this specification is reviewed and approved.

To proceed with implementation, reply with:
- **`proceed`** to start execution of Chunk 1 through Chunk 5.
- Or provide specific adjustments to the regex patterns, UI behavior, or supported banks.
