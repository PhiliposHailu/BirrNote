import 'dart:convert';

/// Represents a validated, structured transaction extracted from a bank SMS.
class ParsedBankSms {
  final double amount;
  final String merchant;
  final String? txnRef;
  final String source; // 'sms_telebirr' | 'sms_cbe'
  final String rawBody;
  final DateTime timestamp;
  final String suggestedCategory;

  const ParsedBankSms({
    required this.amount,
    required this.merchant,
    this.txnRef,
    required this.source,
    required this.rawBody,
    required this.timestamp,
    required this.suggestedCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'merchant': merchant,
      'txnRef': txnRef,
      'source': source,
      'rawBody': rawBody,
      'timestamp': timestamp.toIso8601String(),
      'suggestedCategory': suggestedCategory,
    };
  }

  factory ParsedBankSms.fromMap(Map<String, dynamic> map) {
    return ParsedBankSms(
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String? ?? 'Expense',
      txnRef: map['txnRef'] as String?,
      source: map['source'] as String? ?? 'sms_telebirr',
      rawBody: map['rawBody'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      suggestedCategory: map['suggestedCategory'] as String? ?? 'Others',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ParsedBankSms.fromJson(String source) =>
      ParsedBankSms.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
