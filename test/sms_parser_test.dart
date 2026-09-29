import 'package:flutter_test/flutter_test.dart';
import 'package:birr_note/core/sms/sms_parser.dart';
import 'package:birr_note/core/sms/sms_models.dart';
import 'package:birr_note/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  group('SmsParser - Sender Identification', () {
    test('identifies Telebirr sender variations', () {
      expect(SmsParser.isBankSender('127'), isTrue);
      expect(SmsParser.isBankSender('telebirr'), isTrue);
      expect(SmsParser.isBankSender('TELEBIRR'), isTrue);
      expect(SmsParser.isBankSender('Ethio telecom'), isTrue);
      expect(SmsParser.detectBankSource('127'), 'sms_telebirr');
    });

    test('identifies CBE sender variations', () {
      expect(SmsParser.isBankSender('898'), isTrue);
      expect(SmsParser.isBankSender('CBE'), isTrue);
      expect(SmsParser.isBankSender('cbe birr'), isTrue);
      expect(SmsParser.isBankSender('Commercial Bank of Ethiopia'), isTrue);
      expect(SmsParser.detectBankSource('898'), 'sms_cbe');
    });

    test('rejects non-banking senders and personal numbers', () {
      expect(SmsParser.isBankSender('+251911223344'), isFalse);
      expect(SmsParser.isBankSender('Google'), isFalse);
      expect(SmsParser.isBankSender('Telegram'), isFalse);
      expect(SmsParser.detectBankSource('Spam'), isNull);
    });
  });

  group('SmsParser - Telebirr Parsing', () {
    test('parses Telebirr transfer to person / merchant', () {
      const body =
          'You have transferred ETB 150.00 to Tomoca Coffee. Transaction number is FT12345678.';
      final parsed = SmsParser.parseSms(sender: '127', body: body);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 150.0);
      expect(parsed.merchant, 'Tomoca Coffee');
      expect(parsed.txnRef, 'FT12345678');
      expect(parsed.source, 'sms_telebirr');
      expect(parsed.suggestedCategory, 'Food & Drinks');
    });

    test('parses Telebirr merchant payment with commas in amount', () {
      const body =
          'You have paid ETB 1,450.50 to TOTAL ETHIOPIA. Transaction ID: MP98765432.';
      final parsed = SmsParser.parseSms(sender: 'telebirr', body: body);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1450.50);
      expect(parsed.merchant, 'TOTAL ETHIOPIA');
      expect(parsed.txnRef, 'MP98765432');
      expect(parsed.suggestedCategory, 'Transport');
    });

    test('parses Telebirr cash withdrawal', () {
      const body =
          'You have withdrawn ETB 1000.00. Transaction number is CW55667788.';
      final parsed = SmsParser.parseSms(sender: '127', body: body);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1000.0);
      expect(parsed.merchant, 'Cash Withdrawal');
      expect(parsed.txnRef, 'CW55667788');
      expect(parsed.suggestedCategory, 'Others');
    });

    test('parses Telebirr airtime top-up', () {
      const body =
          'You have bought 50.00 ETB airtime with transaction number AT998877.';
      final parsed = SmsParser.parseSms(sender: 'telebirr', body: body);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 50.0);
      expect(parsed.merchant, 'Airtime Top-up');
      expect(parsed.txnRef, 'AT998877');
      expect(parsed.suggestedCategory, 'Bills');
    });
  });

  group('SmsParser - CBE Parsing', () {
    test('parses CBE account debit SMS', () {
      const body =
          'Dear customer, your account 1000****1234 has been debited with ETB 250.00 on 28/09/2026. Txn ID: FT24270XXX.';
      final parsed = SmsParser.parseSms(sender: 'CBE', body: body);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 250.0);
      expect(parsed.merchant, 'CBE Debit');
      expect(parsed.txnRef, 'FT24270XXX');
      expect(parsed.source, 'sms_cbe');
      expect(parsed.suggestedCategory, 'Others');
    });

    test('parses CBE Birr transfer with phone & name in parentheses', () {
      const body =
          'You have transferred ETB 350.00 to 0911223344 (Abebe Kebede). Ref: CB891234.';
      final parsed = SmsParser.parseSms(sender: '898', body: body);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 350.0);
      expect(parsed.merchant, 'Abebe Kebede');
      expect(parsed.txnRef, 'CB891234');
      expect(parsed.source, 'sms_cbe');
    });

    test('parses CBE payment to supermarket', () {
      const body =
          'Dear customer, you have paid ETB 820.00 to Friendship Supermarket. Txn: 554433.';
      final parsed = SmsParser.parseSms(sender: 'cbe birr', body: body);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 820.0);
      expect(parsed.merchant, 'Friendship Supermarket');
      expect(parsed.suggestedCategory, 'Shopping');
      expect(parsed.txnRef, '554433');
    });
  });

  group('SmsParser - Filtering & Income Ignored', () {
    test('ignores incoming salary / deposits / credits', () {
      const salary =
          'Dear customer, your account has been credited with ETB 25,000.00 on 28/09/2026.';
      expect(SmsParser.parseSms(sender: 'CBE', body: salary), isNull);

      const receivedTelebirr =
          'You have received ETB 500.00 from Abebe Kebede. Transaction number is FT990011.';
      expect(SmsParser.parseSms(sender: '127', body: receivedTelebirr), isNull);
    });

    test('ignores OTPs and generic bank announcements', () {
      const otp = 'Your CBE OTP code is 123456. Do not share it with anyone.';
      expect(SmsParser.parseSms(sender: '898', body: otp), isNull);

      const announcement =
          'Ethio telecom wishes you a happy Ethiopian New Year!';
      expect(SmsParser.parseSms(sender: '127', body: announcement), isNull);
    });
  });

  group('SmsParser - Deduplication via ExpenseDao', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('correctly detects duplicate txnRef in database', () async {
      final expenseDao = db.expenseDao;

      // Initial check - should not exist
      expect(await expenseDao.hasExpenseWithTxnRef('FT12345678'), isFalse);

      // Insert an expense with txnRef
      await expenseDao.insertExpense(
        ExpensesCompanion.insert(
          rawNote: 'Tomoca Coffee',
          amount: const Value(150.0),
          category: const Value('Food & Drinks'),
          date: DateTime.now(),
          source: const Value('sms_telebirr'),
          txnRef: const Value('FT12345678'),
        ),
      );

      // Subsequent check - should now exist!
      expect(await expenseDao.hasExpenseWithTxnRef('FT12345678'), isTrue);

      // Query returns exact expense
      final found = await expenseDao.getExpenseByTxnRef('FT12345678');
      expect(found, isNotNull);
      expect(found!.amount, 150.0);
      expect(found.source, 'sms_telebirr');
      expect(found.txnRef, 'FT12345678');
    });
  });

  group('ParsedBankSms Serialization', () {
    test('serializes to and from JSON correctly', () {
      final now = DateTime(2026, 9, 29, 10, 30);
      final model = ParsedBankSms(
        amount: 250.75,
        merchant: 'Kaldis Coffee',
        txnRef: 'TXN998877',
        source: 'sms_telebirr',
        rawBody: 'sample body text',
        timestamp: now,
        suggestedCategory: 'Food & Drinks',
      );

      final jsonStr = model.toJson();
      final revived = ParsedBankSms.fromJson(jsonStr);

      expect(revived.amount, 250.75);
      expect(revived.merchant, 'Kaldis Coffee');
      expect(revived.txnRef, 'TXN998877');
      expect(revived.source, 'sms_telebirr');
      expect(revived.rawBody, 'sample body text');
      expect(revived.suggestedCategory, 'Food & Drinks');
      expect(revived.timestamp, now);
    });
  });
}
