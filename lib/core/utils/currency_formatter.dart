import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const String defaultLocale = 'en_KE';
  static const String defaultSymbol = 'KES';

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: defaultLocale,
    symbol: defaultSymbol,
    decimalDigits: 2,
  );

  static String money(double amount) => _formatter.format(amount);
}
