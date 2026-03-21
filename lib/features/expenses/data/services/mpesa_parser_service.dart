import 'dart:convert';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';
import 'package:crypto/crypto.dart';

class MpesaParserService {
  const MpesaParserService();
  static final RegExp _codePattern = RegExp(r'^([A-Z0-9]{10})\b');
  static final RegExp _amountPattern = RegExp(
    r'(?:ksh|kes)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _dateTimePattern = RegExp(
    r'on\s+(\d{1,2}/\d{1,2}/\d{2,4})\s+at\s+(\d{1,2}:\d{2}\s?(?:am|pm)?)',
    caseSensitive: false,
  );
  static final RegExp _paybillPattern = RegExp(
    r'(?:for account|account no\.?)\s*([a-z0-9-]{4,})',
    caseSensitive: false,
  );
  static final RegExp _sentToPattern = RegExp(
    r'sent to\s+([a-z0-9 .,&-]{3,}?)(?=\s+(?:for account|on)\b|[.]|$)',
    caseSensitive: false,
  );
  static final RegExp _receivedFromPattern = RegExp(
    r'received from\s+([a-z0-9 .,&-]{3,}?)(?=\s+on\b|[.]|$)',
    caseSensitive: false,
  );
  static final RegExp _paidToPattern = RegExp(
    r'paid to\s+([a-z0-9 .,&-]{3,}?)(?=\s+on\b|[.]|$)',
    caseSensitive: false,
  );

  List<ParsedMpesaTransaction> parseBulkText(String payload) {
    final chunks = payload
        .split(RegExp(r'(?:\r?\n){2,}'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return parseMany(chunks);
  }

  List<ParsedMpesaTransaction> parseMany(List<String> messages) {
    return parseManyDetailed(messages)
        .where((item) => item.route != MpesaParseRoute.quarantine)
        .map(
          (item) => ParsedMpesaTransaction(
            title: item.title,
            category: item.category,
            amountKes: item.amountKes,
            occurredAt: item.occurredAt,
            rawMessage: item.rawMessage,
          ),
        )
        .toList();
  }

  List<ParsedMpesaCandidate> parseManyDetailed(List<String> messages) {
    final results = <ParsedMpesaCandidate>[];
    for (final message in messages) {
      final parsed = parseSingleDetailed(message);
      if (parsed != null) {
        results.add(parsed);
      }
    }
    return results;
  }

  ParsedMpesaTransaction? parseSingle(String message) {
    final detailed = parseSingleDetailed(message);
    if (detailed == null || detailed.route == MpesaParseRoute.quarantine) {
      return null;
    }
    return ParsedMpesaTransaction(
      title: detailed.title,
      category: detailed.category,
      amountKes: detailed.amountKes,
      occurredAt: detailed.occurredAt,
      rawMessage: detailed.rawMessage,
    );
  }

  ParsedMpesaCandidate? parseSingleDetailed(String message) {
    final cleaned = normalizeParserText(message);
    if (cleaned.isEmpty || !looksLikeMpesaMessage(cleaned)) {
      return null;
    }
    final code = _extractMpesaCode(cleaned);
    if (code == null) {
      return _buildQuarantine(cleaned, reason: 'Missing MPESA code');
    }
    final amount = _extractAmount(cleaned);
    if (amount == null || amount <= 0) {
      return _buildQuarantine(cleaned, reason: 'Missing amount');
    }
    final occurredAt =
        parseMpesaDateTime(cleaned, _dateTimePattern) ?? DateTime.now();
    final (type, confidence, reason) = _detect(cleaned);
    final counterparty = _extractCounterparty(cleaned, type);
    final title = _buildTitle(type, counterparty);
    final source = sourceHash(cleaned);
    return ParsedMpesaCandidate(
      mpesaCode: code,
      title: title,
      category: _categoryFor(type, cleaned),
      amountKes: amount,
      occurredAt: occurredAt,
      rawMessage: cleaned,
      transactionType: type,
      confidence: confidence,
      route: _routeFor(confidence),
      sourceHash: source,
      semanticHash: semanticHash(
        type: type,
        amountKes: amount,
        occurredAt: occurredAt,
        title: title,
      ),
      counterparty: counterparty,
      reason: reason,
      paybillAccount: _extractPaybillAccount(cleaned),
    );
  }

  String sourceHash(String message) =>
      sha256.convert(utf8.encode(normalizeParserText(message))).toString();

  String semanticHash({
    required MpesaTransactionType type,
    required double amountKes,
    required DateTime occurredAt,
    required String title,
  }) {
    final key =
        '${type.name}|${amountKes.toStringAsFixed(2)}|${occurredAt.year}-${occurredAt.month}-${occurredAt.day}|${title.toLowerCase()}';
    return sha256.convert(utf8.encode(key)).toString();
  }

  ParsedMpesaCandidate _buildQuarantine(
    String cleaned, {
    required String reason,
  }) {
    final occurredAt = DateTime.now();
    return ParsedMpesaCandidate(
      mpesaCode: 'UNKNOWN',
      title: 'Unclassified MPESA Message',
      category: 'Other',
      amountKes: 0,
      occurredAt: occurredAt,
      rawMessage: cleaned,
      transactionType: MpesaTransactionType.unknown,
      confidence: MpesaConfidence.low,
      route: MpesaParseRoute.quarantine,
      sourceHash: sourceHash(cleaned),
      semanticHash: semanticHash(
        type: MpesaTransactionType.unknown,
        amountKes: 0,
        occurredAt: occurredAt,
        title: 'unknown',
      ),
      reason: reason,
    );
  }

  (MpesaTransactionType, MpesaConfidence, String) _detect(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('has been reversed')) {
      return (MpesaTransactionType.reversal, MpesaConfidence.high, 'reversal');
    }
    if (lower.contains('from your fuliza')) {
      return (
        MpesaTransactionType.fulizaRepayment,
        MpesaConfidence.high,
        'fuliza_repayment',
      );
    }
    if (lower.contains('fuliza m-pesa') && lower.contains('credited')) {
      return (MpesaTransactionType.fulizaDraw, MpesaConfidence.high, 'fuliza');
    }
    if (lower.contains('received from')) {
      return (MpesaTransactionType.received, MpesaConfidence.high, 'receive');
    }
    if (lower.contains('sent to') && lower.contains('for account')) {
      return (MpesaTransactionType.paybill, MpesaConfidence.high, 'paybill');
    }
    if (lower.contains('paid to')) {
      return (MpesaTransactionType.buyGoods, MpesaConfidence.high, 'buy_goods');
    }
    if (lower.contains('sent to')) {
      return (MpesaTransactionType.sent, MpesaConfidence.high, 'sent');
    }
    if (lower.contains('withdraw')) {
      return (
        MpesaTransactionType.withdrawal,
        MpesaConfidence.medium,
        'withdrawal',
      );
    }
    if (lower.contains('airtime')) {
      return (MpesaTransactionType.airtime, MpesaConfidence.medium, 'airtime');
    }
    if (lower.contains('deposit')) {
      return (MpesaTransactionType.deposit, MpesaConfidence.medium, 'deposit');
    }
    return (MpesaTransactionType.unknown, MpesaConfidence.low, 'fallback');
  }

  MpesaParseRoute _routeFor(MpesaConfidence confidence) => switch (confidence) {
        MpesaConfidence.high => MpesaParseRoute.directLedger,
        MpesaConfidence.medium => MpesaParseRoute.reviewQueue,
        MpesaConfidence.low => MpesaParseRoute.quarantine,
      };

  String _categoryFor(MpesaTransactionType type, String message) =>
      switch (type) {
        MpesaTransactionType.received => 'Income',
        MpesaTransactionType.paybill => 'Bills',
        MpesaTransactionType.buyGoods => 'Food',
        MpesaTransactionType.withdrawal => 'Cash',
        MpesaTransactionType.deposit => 'Cash',
        MpesaTransactionType.airtime => 'Airtime',
        MpesaTransactionType.fulizaDraw => 'Loan',
        MpesaTransactionType.fulizaRepayment => 'Loan',
        MpesaTransactionType.unknown =>
          message.toLowerCase().contains('salary') ? 'Income' : 'Other',
        _ => 'Other',
      };

  String? _extractCounterparty(String message, MpesaTransactionType type) {
    final pattern = switch (type) {
      MpesaTransactionType.sent => _sentToPattern,
      MpesaTransactionType.received => _receivedFromPattern,
      MpesaTransactionType.paybill => _sentToPattern,
      MpesaTransactionType.buyGoods => _paidToPattern,
      _ => null,
    };
    final value = pattern?.firstMatch(message)?.group(1)?.trim();
    return value == null || value.isEmpty ? null : titleCaseWords(value);
  }

  String _buildTitle(MpesaTransactionType type, String? counterparty) {
    if (counterparty != null) {
      return counterparty;
    }
    return switch (type) {
      MpesaTransactionType.sent => 'MPESA Send',
      MpesaTransactionType.received => 'MPESA Receive',
      MpesaTransactionType.paybill => 'Paybill Payment',
      MpesaTransactionType.buyGoods => 'Buy Goods',
      MpesaTransactionType.withdrawal => 'Cash Withdrawal',
      MpesaTransactionType.deposit => 'Cash Deposit',
      MpesaTransactionType.airtime => 'Airtime Topup',
      MpesaTransactionType.reversal => 'MPESA Reversal',
      MpesaTransactionType.fulizaDraw => 'Fuliza Draw',
      MpesaTransactionType.fulizaRepayment => 'Fuliza Repayment',
      MpesaTransactionType.unknown => 'MPESA Transaction',
    };
  }

  String? _extractPaybillAccount(String message) =>
      _paybillPattern.firstMatch(message)?.group(1)?.trim();

  String? _extractMpesaCode(String message) =>
      _codePattern.firstMatch(message)?.group(1);

  double? _extractAmount(String message) {
    final value = _amountPattern.firstMatch(message)?.group(1);
    return value == null ? null : double.tryParse(value.replaceAll(',', ''));
  }
}
