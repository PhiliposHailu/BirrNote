import 'package:easy_sms_receiver/easy_sms_receiver.dart';
import '../database/daos/expense_dao.dart';
import '../notifications/notification_service.dart';
import 'sms_models.dart';
import 'sms_parser.dart';

/// Background service to monitor incoming banking SMS from Telebirr and CBE
class SmsListenerService {
  SmsListenerService._internal();
  static final SmsListenerService _instance = SmsListenerService._internal();
  factory SmsListenerService() => _instance;

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Starts listening to incoming SMS using EasySmsReceiver
  Future<void> startListening({
    required ExpenseDao expenseDao,
    Future<void> Function(ParsedBankSms)? onParsedTransaction,
  }) async {
    if (_isListening) return;

    try {
      EasySmsReceiver.instance.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          await handleIncomingMessage(
            sender: message.address,
            body: message.body,
            expenseDao: expenseDao,
            onParsedTransaction: onParsedTransaction,
          );
        },
      );
      _isListening = true;
    } catch (e) {
      // Gracefully handle environments where SMS receiver is unsupported (e.g. desktop/simulator)
      _isListening = false;
    }
  }

  /// Stops listening to incoming SMS
  void stopListening() {
    if (!_isListening) return;
    try {
      EasySmsReceiver.instance.stopListenIncomingSms();
    } catch (_) {}
    _isListening = false;
  }

  /// Processes raw incoming SMS data through the parser, dedup filter, and notification pipeline
  Future<ParsedBankSms?> handleIncomingMessage({
    required String? sender,
    required String? body,
    required ExpenseDao expenseDao,
    Future<void> Function(ParsedBankSms)? onParsedTransaction,
  }) async {
    if (sender == null || body == null || body.trim().isEmpty) {
      return null;
    }

    // 1. Verify sender whitelist (Telebirr or CBE)
    if (!SmsParser.isBankSender(sender)) {
      return null;
    }

    // 2. Deterministic on-device parsing
    final parsed = SmsParser.parseSms(
      sender: sender,
      body: body,
      timestamp: DateTime.now(),
    );
    if (parsed == null) {
      return null;
    }

    // 3. Deduplication check against local Drift database
    if (parsed.txnRef != null && parsed.txnRef!.isNotEmpty) {
      final exists = await expenseDao.hasExpenseWithTxnRef(parsed.txnRef!);
      if (exists) {
        return null; // Already logged, suppress notification
      }
    }

    // 4. Trigger rich local notification
    final notifId =
        (parsed.txnRef?.hashCode ?? DateTime.now().millisecondsSinceEpoch)
            .abs() %
        100000;

    final title =
        '✦ Detected ${parsed.amount.toStringAsFixed(2)} ETB to ${parsed.merchant}';
    final notifBody = 'Tap to review and log in BirrNote.';

    await NotificationService().showSmsTransactionNotification(
      id: notifId,
      title: title,
      body: notifBody,
      payload: parsed.toJson(),
    );

    if (onParsedTransaction != null) {
      await onParsedTransaction(parsed);
    }

    return parsed;
  }
}
