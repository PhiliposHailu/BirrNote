import 'sms_models.dart';

/// Deterministic, on-device regex parser for Ethiopian banking SMS alerts.
class SmsParser {
  static const Set<String> telebirrSenders = {
    '127',
    'telebirr',
    'ethio telecom',
    'ethiotelecom',
  };

  static const Set<String> cbeSenders = {
    '898',
    'cbe',
    'cbe birr',
    'cbebirr',
    'commercial bank of ethiopia',
  };

  /// Checks if the sender address matches supported Ethiopian financial institutions.
  static bool isBankSender(String? sender) {
    if (sender == null) return false;
    final normalized = sender.trim().toLowerCase();
    return telebirrSenders.contains(normalized) ||
        cbeSenders.contains(normalized);
  }

  /// Identifies the bank source: 'sms_telebirr' or 'sms_cbe', or null if unknown.
  static String? detectBankSource(String? sender) {
    if (sender == null) return null;
    final normalized = sender.trim().toLowerCase();
    if (telebirrSenders.contains(normalized)) return 'sms_telebirr';
    if (cbeSenders.contains(normalized)) return 'sms_cbe';
    return null;
  }

  /// Parses incoming SMS text into a structured ParsedBankSms.
  /// Returns null if the message is not an expense/debit, is a credit/deposit, or cannot be parsed.
  static ParsedBankSms? parseSms({
    required String? sender,
    required String body,
    DateTime? timestamp,
  }) {
    if (body.trim().isEmpty) return null;
    final source = detectBankSource(sender);
    if (source == null) return null;

    final lower = body.toLowerCase();

    // Guard: ignore incoming deposits/credits (income is not tracked as an expense)
    if (lower.contains('credited with') ||
        lower.contains('you have received') ||
        lower.contains('received etb') ||
        lower.contains('deposited')) {
      return null;
    }

    if (source == 'sms_telebirr') {
      return _parseTelebirr(body, timestamp ?? DateTime.now());
    } else {
      return _parseCbe(body, timestamp ?? DateTime.now());
    }
  }

  // ---------------------------------------------------------------------------
  // TELEBIRR PARSER
  // ---------------------------------------------------------------------------
  static ParsedBankSms? _parseTelebirr(String body, DateTime timestamp) {
    // 1. Amount Extraction
    // Patterns:
    // - "transferred ETB 150.00 to ..."
    // - "paid ETB 450.50 to ..."
    // - "withdrawn ETB 1,000.00"
    // - "bought 50.00 ETB airtime" / "bought ETB 50.00"
    // - "debited ETB 100.00"
    final amountRegex = RegExp(
      r'(?:transferred|paid|withdrawn|debited|bought)\s+(?:ETB|Birr)?\s*([\d,]+\.?\d*)|(?:bought)\s+([\d,]+\.?\d*)\s*(?:ETB|Birr)',
      caseSensitive: false,
    );

    final amountMatch = amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    final rawAmountStr = (amountMatch.group(1) ?? amountMatch.group(2) ?? '')
        .replaceAll(',', '');
    final amount = double.tryParse(rawAmountStr);
    if (amount == null || amount <= 0) return null;

    // 2. Merchant / Payee Extraction
    String merchant = 'Telebirr Payment';
    final toMerchantRegex = RegExp(
      r'\b(?:to|at)\s+([^.]+?)(?:\.|\s*Transaction|\s*Txn|\s*Ref|\s*$)',
      caseSensitive: false,
    );
    final toMatch = toMerchantRegex.firstMatch(body);
    if (toMatch != null) {
      final candidate = toMatch.group(1)?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        merchant = _cleanMerchantName(candidate);
      }
    } else if (body.toLowerCase().contains('withdrawn')) {
      merchant = 'Cash Withdrawal';
    } else if (body.toLowerCase().contains('airtime')) {
      merchant = 'Airtime Top-up';
    }

    // 3. Transaction Reference Extraction
    // Patterns: "Transaction number is FT12345678", "Transaction ID: MP98765432", "Txn: 12345"
    final txnRegex = RegExp(
      r'(?:Transaction\s*(?:number|no|id|#)?|Txn\s*(?:id|no|#)?|Ref(?:\s*(?:no|id|#))?)\s*(?:is|:)?\s*([A-Za-z0-9]+)',
      caseSensitive: false,
    );
    final txnMatch = txnRegex.firstMatch(body);
    final txnRef = txnMatch?.group(1)?.trim();

    final category = suggestCategory(merchant, body);

    return ParsedBankSms(
      amount: amount,
      merchant: merchant,
      txnRef: txnRef,
      source: 'sms_telebirr',
      rawBody: body,
      timestamp: timestamp,
      suggestedCategory: category,
    );
  }

  // ---------------------------------------------------------------------------
  // CBE (Commercial Bank of Ethiopia) PARSER
  // ---------------------------------------------------------------------------
  static ParsedBankSms? _parseCbe(String body, DateTime timestamp) {
    // 1. Amount Extraction
    // Patterns:
    // - "debited with ETB 250.00"
    // - "transferred ETB 350.00 to ..."
    // - "paid ETB 500.00"
    // - "deducted ETB 100.00"
    final amountRegex = RegExp(
      r'(?:debited\s+with|transferred|paid|deducted)\s+(?:ETB|Birr)?\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    final amountMatch = amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    final rawAmountStr = (amountMatch.group(1) ?? '').replaceAll(',', '');
    final amount = double.tryParse(rawAmountStr);
    if (amount == null || amount <= 0) return null;

    // 2. Merchant / Payee Extraction
    String merchant = 'CBE Transfer';
    final toMerchantRegex = RegExp(
      r'\b(?:to|at)\s+([^.]+?)(?:\.|\s*Ref|\s*Txn|\s*on\s+\d|\s*$)',
      caseSensitive: false,
    );
    final toMatch = toMerchantRegex.firstMatch(body);
    if (toMatch != null) {
      final candidate = toMatch.group(1)?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        merchant = _cleanMerchantName(candidate);
      }
    } else if (body.toLowerCase().contains('account') &&
        body.toLowerCase().contains('debited')) {
      merchant = 'CBE Debit';
    }

    // 3. Transaction Reference Extraction
    // Patterns: "Txn ID: FT24270XXX", "Ref: CB891234", "Transaction ID 1234"
    final txnRegex = RegExp(
      r'(?:Transaction\s*(?:number|no|id|#)?|Txn\s*(?:id|no|#)?|Ref(?:\s*(?:no|id|#))?)\s*(?:is|:)?\s*([A-Za-z0-9]+)',
      caseSensitive: false,
    );
    final txnMatch = txnRegex.firstMatch(body);
    final txnRef = txnMatch?.group(1)?.trim();

    final category = suggestCategory(merchant, body);

    return ParsedBankSms(
      amount: amount,
      merchant: merchant,
      txnRef: txnRef,
      source: 'sms_cbe',
      rawBody: body,
      timestamp: timestamp,
      suggestedCategory: category,
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: CLEAN MERCHANT NAME
  // ---------------------------------------------------------------------------
  static String _cleanMerchantName(String raw) {
    // Strip trailing punctuation and excessive whitespace
    var cleaned = raw.trim();
    cleaned = cleaned.replaceAll(RegExp(r'[\.,;:]+$'), '').trim();

    // If it's a phone number with name in parentheses like "0911223344 (Abebe Kebede)", extract "Abebe Kebede"
    final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(cleaned);
    if (parenMatch != null) {
      final inside = parenMatch.group(1)?.trim();
      if (inside != null &&
          inside.isNotEmpty &&
          !inside.contains(RegExp(r'^\d+$'))) {
        return inside;
      }
    }

    return cleaned;
  }

  // ---------------------------------------------------------------------------
  // SMART CATEGORY SUGGESTER
  // ---------------------------------------------------------------------------
  static String suggestCategory(String merchant, String fullText) {
    final combined = '$merchant $fullText'.toLowerCase();

    // 1. Food & Drinks
    if (combined.contains('cafe') ||
        combined.contains('coffee') ||
        combined.contains('tomoca') ||
        combined.contains('kaldis') ||
        combined.contains('restaurant') ||
        combined.contains('burger') ||
        combined.contains('pizza') ||
        combined.contains('bar') ||
        combined.contains('lounge') ||
        combined.contains('pastry') ||
        combined.contains('bakery') ||
        combined.contains('lunch') ||
        combined.contains('dinner') ||
        combined.contains('breakfast') ||
        combined.contains('juice') ||
        combined.contains('hotel')) {
      return 'Food & Drinks';
    }

    // 2. Transport
    if (combined.contains('ride') ||
        combined.contains('feres') ||
        combined.contains('taxi') ||
        combined.contains('fuel') ||
        combined.contains('total') ||
        combined.contains('oil') ||
        combined.contains('nog') ||
        combined.contains('gas') ||
        combined.contains('transport') ||
        combined.contains('bus') ||
        combined.contains('train') ||
        combined.contains('airlines')) {
      return 'Transport';
    }

    // 3. Bills & Utilities
    if (combined.contains('electric') ||
        combined.contains('water') ||
        combined.contains('internet') ||
        combined.contains('telecom') ||
        combined.contains('airtime') ||
        combined.contains('package') ||
        combined.contains('dstv') ||
        combined.contains('canal') ||
        combined.contains('rent') ||
        combined.contains('utility')) {
      return 'Bills';
    }

    // 4. Shopping
    if (combined.contains('supermarket') ||
        combined.contains('market') ||
        combined.contains('mall') ||
        combined.contains('mart') ||
        combined.contains('store') ||
        combined.contains('shop') ||
        combined.contains('boutique') ||
        combined.contains('pharmacy') ||
        combined.contains('clothes')) {
      return 'Shopping';
    }

    return 'Others';
  }
}
