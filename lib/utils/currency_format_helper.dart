// lib/utils/currency_format_helper.dart
import '../services/currency_service.dart';

class CurrencyFormatHelper {
  // Format amount with the current currency symbol
  static Future<String> formatAmount(double amount) async {
    final symbol = await CurrencyService.instance.getCurrencySymbol();
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  // Format with a plus/minus prefix for transactions
  static Future<String> formatWithPrefix(double amount, bool isIncome) async {
    final symbol = await CurrencyService.instance.getCurrencySymbol();
    final prefix = isIncome ? '+' : '-';
    return '$prefix$symbol${amount.toStringAsFixed(2)}';
  }

  // Get just the currency symbol
  static Future<String> getCurrencySymbol() async {
    return await CurrencyService.instance.getCurrencySymbol();
  }
}
