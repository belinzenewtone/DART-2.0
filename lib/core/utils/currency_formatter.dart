import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const String defaultLocale = 'en_KE';
  static const String defaultSymbol = 'KES';
  static const String _wordJoiner = '\u2060';

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: defaultLocale,
    symbol: defaultSymbol,
    decimalDigits: 2,
  );

  /// Compact form: "KES 4.2K" or "KES 1.3M" — ideal for space-constrained KPI chips.
  static String compact(double amount) {
    if (amount >= 1000000) {
      return 'KES ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'KES ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'KES ${amount.toStringAsFixed(0)}';
  }

  static String money(double amount) {
    final formatted = _formatter.format(amount);
    final decimalSeparator = _formatter.symbols.DECIMAL_SEP;
    final decimalIndex = formatted.lastIndexOf(decimalSeparator);
    if (decimalIndex == -1 || decimalIndex == formatted.length - 1) {
      return formatted;
    }
    // Prevent fractional digits from wrapping onto a new line.
    return '${formatted.substring(0, decimalIndex + 1)}$_wordJoiner${formatted.substring(decimalIndex + 1)}';
  }
}
