import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_rate.dart';

class PrefsService {
  static const _keyRates = 'cached_currency_rates';

  /// Lưu tỉ giá
  static Future<void> saveRates(CurrencyRate rate) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode(rate.toJson());
    await prefs.setString(_keyRates, jsonData);
  }

  /// Đọc tỉ giá đã lưu (nếu có)
  static Future<CurrencyRate?> loadRates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyRates);
    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      return CurrencyRate.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
