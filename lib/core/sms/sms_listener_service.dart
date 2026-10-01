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
    Future<void> Function({
      required int id,
      required String title,
      required String body,
      required String payload,
    })?
    onNotify,
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
      effectiveRef =
          '${parsed.source}_${parsed.amount.toStringAsFixed(2)}_${roundedTs.millisecondsSinceEpoch}';
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

    // 4. Trigger rich local notification
    final notifId =
        (enrichedParsed.txnRef?.hashCode ??
                DateTime.now().millisecondsSinceEpoch)
            .abs() %
        100000;

    final title =
        '✦ Detected ${enrichedParsed.amount.toStringAsFixed(2)} ETB to ${enrichedParsed.merchant}';
    final notifBody = 'Tap to review and log in BirrNote.';

    if (onNotify != null) {
      await onNotify(
        id: notifId,
        title: title,
        body: notifBody,
        payload: enrichedParsed.toJson(),
      );
    } else {
      await NotificationService().showSmsTransactionNotification(
        id: notifId,
        title: title,
        body: notifBody,
        payload: enrichedParsed.toJson(),
      );
    }

    if (onParsedTransaction != null) {
      await onParsedTransaction(enrichedParsed);
    }

    return enrichedParsed;
  }
}
