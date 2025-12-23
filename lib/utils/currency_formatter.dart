import 'package:intl/intl.dart';

String formatCurrencyLabel(String rawLabel, String locale) {
  // Ví dụ rawLabel = "VND_10000"

  if (!rawLabel.contains("_")) return rawLabel;

  final parts = rawLabel.split("_");
  final currency = parts.first;   // VND
  final valueStr = parts.last;    // 10000

  final amount = int.tryParse(valueStr);
  if (amount == null) return rawLabel;

  // Format theo locale
  final formatter = NumberFormat.decimalPattern(locale);
  final formatted = formatter.format(amount);

  // Trả về theo ngôn ngữ
  if (currency == "VND") {
    return locale == "vi" ? "$formatted VNĐ" : "$formatted VND";
  }

  return "$formatted $currency";
}
