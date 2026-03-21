import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MpesaParserService();

  test('high-confidence sent transaction routes to direct ledger', () {
    final parsed = parser.parseSingleDetailed(
      'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.',
    );

    expect(parsed, isNotNull);
    expect(parsed!.confidence, MpesaConfidence.high);
    expect(parsed.route, MpesaParseRoute.directLedger);
    expect(parsed.amountKes, 1250.0);
  });

  test('withdrawal message routes to review queue', () {
    final parsed = parser.parseSingleDetailed(
      'AB12CD34EF Confirmed. Ksh300.00 withdrawn at ATM on 8/3/26 at 10:00 AM.',
    );

    expect(parsed, isNotNull);
    expect(parsed!.confidence, MpesaConfidence.medium);
    expect(parsed.route, MpesaParseRoute.reviewQueue);
  });

  test('fallback classification routes to quarantine', () {
    final parsed = parser.parseSingleDetailed(
      'ZZ11YY22XX Confirmed. Ksh50.00 transfer noted on 7/3/26 at 4:00 PM.',
    );

    expect(parsed, isNotNull);
    expect(parsed!.confidence, MpesaConfidence.low);
    expect(parsed.route, MpesaParseRoute.quarantine);
  });

  test('semantic hash is deterministic for the same message', () {
    const sms =
        'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.';
    final one = parser.parseSingleDetailed(sms);
    final two = parser.parseSingleDetailed(sms);

    expect(one, isNotNull);
    expect(two, isNotNull);
    expect(one!.semanticHash, two!.semanticHash);
    expect(one.sourceHash, two.sourceHash);
  });

  test('paybill messages preserve merchant title and paybill reference', () {
    final parsed = parser.parseSingleDetailed(
      'QW12AB34CD Confirmed. Ksh1,250.00 sent to KPLC PREPAID for account 998877 on 7/3/26 at 6:24 PM.',
    );

    expect(parsed, isNotNull);
    expect(parsed!.transactionType, MpesaTransactionType.paybill);
    expect(parsed.title, 'Kplc Prepaid');
    expect(parsed.paybillAccount, '998877');
  });

  test('fuliza draw and repayment are classified directly', () {
    final draw = parser.parseSingleDetailed(
      'AA12BB34CC Confirmed. Ksh500.00 Fuliza M-PESA amount credited on 8/3/26 at 10:00 AM.',
    );
    final repayment = parser.parseSingleDetailed(
      'DD56EE78FF Confirmed. Ksh200.00 paid from your Fuliza M-PESA on 8/3/26 at 2:30 PM.',
    );

    expect(draw, isNotNull);
    expect(repayment, isNotNull);
    expect(draw!.transactionType, MpesaTransactionType.fulizaDraw);
    expect(draw.route, MpesaParseRoute.directLedger);
    expect(repayment!.transactionType, MpesaTransactionType.fulizaRepayment);
    expect(repayment.route, MpesaParseRoute.directLedger);
  });
}
