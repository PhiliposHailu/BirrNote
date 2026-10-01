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
    test(
      'processes valid Telebirr SMS and triggers callback and notification',
      () async {
        ParsedBankSms? captured;
        int? notifId;
        String? notifTitle;

        final result = await SmsListenerService().handleIncomingMessage(
          sender: '127',
          body:
              'You have transferred ETB 150.00 to Tomoca Coffee. Transaction number is FT99887766.',
          expenseDao: db.expenseDao,
          onParsedTransaction: (sms) async {
            captured = sms;
          },
          onNotify:
              ({
                required int id,
                required String title,
                required String body,
                required String payload,
              }) async {
                notifId = id;
                notifTitle = title;
              },
        );

        expect(result, isNotNull);
        expect(result!.amount, 150.0);
        expect(result.merchant, 'Tomoca Coffee');
        expect(result.txnRef, 'FT99887766');
        expect(captured, isNotNull);
        expect(notifId, isNotNull);
        expect(notifTitle, contains('150.00 ETB to Tomoca Coffee'));
      },
    );

    test('rejects non-bank senders', () async {
      final result = await SmsListenerService().handleIncomingMessage(
        sender: '+251911223344',
        body: 'Hey, can you send me 500 birr?',
        expenseDao: db.expenseDao,
        onNotify:
            ({
              required id,
              required title,
              required body,
              required payload,
            }) async {},
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
        body:
            'You have transferred ETB 150.00 to Tomoca Coffee. Transaction number is FT99887766.',
        expenseDao: db.expenseDao,
        onNotify:
            ({
              required id,
              required title,
              required body,
              required payload,
            }) async {},
      );

      expect(result, isNull); // Suppressed — already exists
    });

    test(
      'deduplicates by fallback fingerprint when txnRef is missing',
      () async {
        // Create SMS body that matches parser but has no transaction ref pattern
        const noRefBody = 'You have paid ETB 200.00 to Kaldis Coffee.';

        // First run: should succeed and generate fallback fingerprint
        final firstResult = await SmsListenerService().handleIncomingMessage(
          sender: 'telebirr',
          body: noRefBody,
          expenseDao: db.expenseDao,
          onNotify:
              ({
                required id,
                required title,
                required body,
                required payload,
              }) async {},
        );

        expect(firstResult, isNotNull);
        expect(firstResult!.txnRef, isNotNull);
        expect(firstResult.txnRef, startsWith('sms_telebirr_200.00_'));

        // Simulate user saving the expense with that generated fallback txnRef
        await db.expenseDao.insertExpense(
          ExpensesCompanion.insert(
            rawNote: firstResult.merchant,
            amount: Value(firstResult.amount),
            category: Value(firstResult.suggestedCategory),
            date: firstResult.timestamp,
            source: Value(firstResult.source),
            txnRef: Value(firstResult.txnRef),
          ),
        );

        // Second run within the same minute: should be deduplicated
        final secondResult = await SmsListenerService().handleIncomingMessage(
          sender: 'telebirr',
          body: noRefBody,
          expenseDao: db.expenseDao,
          onNotify:
              ({
                required id,
                required title,
                required body,
                required payload,
              }) async {},
        );

        expect(secondResult, isNull); // Deduplicated by fallback fingerprint!
      },
    );

    test('handles null sender and empty body gracefully', () async {
      expect(
        await SmsListenerService().handleIncomingMessage(
          sender: null,
          body: 'test',
          expenseDao: db.expenseDao,
          onNotify:
              ({
                required id,
                required title,
                required body,
                required payload,
              }) async {},
        ),
        isNull,
      );
      expect(
        await SmsListenerService().handleIncomingMessage(
          sender: '127',
          body: '',
          expenseDao: db.expenseDao,
          onNotify:
              ({
                required id,
                required title,
                required body,
                required payload,
              }) async {},
        ),
        isNull,
      );
    });
  });
}
