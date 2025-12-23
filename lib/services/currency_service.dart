import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency_rate.dart';

class CurrencyService {
  static const _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  /// Tải tỉ giá từ API chính thức
  static Future<CurrencyRate?> fetchRates() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CurrencyRate.fromJson({
          "base": data["base_code"],
          "date": data["time_last_update_utc"],
          "rates": data["rates"],
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi khi gọi API: $e');
      return null;
    }
  }

  /// Dữ liệu tỉ giá dự phòng khi không có mạng
  static CurrencyRate getOfflineBackup() {
    return CurrencyRate(
      base: 'USD',
      date: '2025-10-22',
      rates: {
        'USD': 1.0,
        'VND': 25400.0,
        'EUR': 0.93,
        'JPY': 156.3,
        'GBP': 0.81,
        'AUD': 1.54,
        'KRW': 1376.5,
        'CNY': 7.12,
      },
    );
  }
}
