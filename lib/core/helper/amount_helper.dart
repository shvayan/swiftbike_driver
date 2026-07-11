import 'package:intl/intl.dart';

class AmountHelper {
  static String format(
    num? amount, {
    String symbol = '₹',
    int decimalDigits = 2,
  }) {
    if (amount == null) {
      return '${symbol}0.00';
    }

    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  static String plain(num? amount, {int decimalDigits = 2}) {
    if (amount == null) return '0.00';

    return NumberFormat('#,##0.${'0' * decimalDigits}').format(amount);
  }
}
