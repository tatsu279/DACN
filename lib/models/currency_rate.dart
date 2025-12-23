class CurrencyRate {
  final String base;
  final String date;
  final Map<String, double> rates;

  CurrencyRate({
    required this.base,
    required this.date,
    required this.rates,
  });

  factory CurrencyRate.fromJson(Map<String, dynamic> json) {
    final rates = Map<String, double>.from(
        (json['rates'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    ));

    return CurrencyRate(
      base: json['base'] ?? 'USD',
      date: json['date'] ?? '',
      rates: rates,
    );
  }

  Map<String, dynamic> toJson() => {
        'base': base,
        'date': date,
        'rates': rates,
      };
}
