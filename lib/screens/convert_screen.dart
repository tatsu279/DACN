import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../models/currency_rate.dart';
import '../services/currency_service.dart';
import '../services/prefs_service.dart';
import '../data/currency_info.dart';
import 'currency_lookup_screen.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  String fromCurrency = 'USD';
  String toCurrency = 'VND';
  double inputAmount = 0;
  double resultAmount = 0;
  bool _isLoading = false;
  Map<String, double> exchangeRates = {};
  String lastUpdated = '';

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
  }

  Future<void> _fetchExchangeRates() async {
    setState(() => _isLoading = true);
    final online = await CurrencyService.fetchRates();
    if (online != null) {
      await PrefsService.saveRates(online);
      _setRateData(online);
    } else {
      final cached =
          await PrefsService.loadRates() ?? CurrencyService.getOfflineBackup();
      _setRateData(cached);
    }
    setState(() => _isLoading = false);
  }

  void _setRateData(CurrencyRate rate) {
    setState(() {
      exchangeRates = rate.rates;
      lastUpdated = rate.date;
    });
  }

  void _convertCurrency() {
    if (inputAmount <= 0 || exchangeRates.isEmpty) return;
    double fromRate = exchangeRates[fromCurrency] ?? 1;
    double toRate = exchangeRates[toCurrency] ?? 1;
    setState(() {
      resultAmount = inputAmount * (toRate / fromRate);
    });
  }

  void _swapCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
    });
    _convertCurrency();
  }

  @override
  Widget build(BuildContext context) {
    final currencyCodes = exchangeRates.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('convert_title'.tr()),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'update_rates'.tr(),
            onPressed: _fetchExchangeRates,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : exchangeRates.isEmpty
              ? Center(child: Text('no_rate_data'.tr()))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (lastUpdated.isNotEmpty)
                          Text('${'last_update'.tr()}: $lastUpdated',
                              style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 20),

                        // 🔹 Currency FROM selector
                        _buildCurrencySelector(true, currencyCodes),

                        const SizedBox(height: 10),

                        IconButton(
                          icon: const Icon(Icons.swap_vert,
                              size: 30, color: Colors.teal),
                          tooltip: 'swap'.tr(),
                          onPressed: _swapCurrencies,
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Currency TO selector
                        _buildCurrencySelector(false, currencyCodes),

                        const SizedBox(height: 20),

                        // 🔹 Input amount
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'enter_amount'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            inputAmount = double.tryParse(v) ?? 0;
                            _convertCurrency();
                          },
                        ),
                        const SizedBox(height: 24),

                        // 🔹 Result Card
                        _buildResultCard(),

                        const SizedBox(height: 20),
                        Text(
                          'data_source'.tr(),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCurrencySelector(bool isFrom, List<String> codes) {
    final currentCode = isFrom ? fromCurrency : toCurrency;
    final desc = currencyDescriptions[currentCode] ?? currentCode;
    final flag = _getFlagEmoji(currentCode);
    final match = RegExp(r'\((.*?)\)').firstMatch(desc);
    final country = match != null ? match.group(1)! : '';

    return InkWell(
      onTap: () async {
        final selectedCode = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CurrencyLookupScreen(selectedCode: currentCode),
          ),
        );
        if (selectedCode != null) {
          setState(() {
            if (isFrom) {
              fromCurrency = selectedCode;
            } else {
              toCurrency = selectedCode;
            }
          });
          _convertCurrency();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$currentCode – $country',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final fromDesc = currencyDescriptions[fromCurrency] ?? fromCurrency;
    final toDesc = currencyDescriptions[toCurrency] ?? toCurrency;
    final hasResult = inputAmount > 0 && resultAmount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasResult ? Colors.teal.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          if (hasResult)
            Column(
              children: [
                Text('${inputAmount.toStringAsFixed(2)} $fromCurrency',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500)),
                Text(fromDesc,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 12),
                const Icon(Icons.arrow_downward, color: Colors.teal, size: 28),
                const SizedBox(height: 12),
                Text('${resultAmount.toStringAsFixed(2)} $toCurrency',
                    style: const TextStyle(
                        fontSize: 24,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold)),
                Text(toDesc,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0)
          else
            Text(
              'enter_to_convert'.tr(),
              style: const TextStyle(color: Colors.black45, fontSize: 14),
            ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  String _getFlagEmoji(String code) {
    const specialMap = {
      'USD': 'US',
      'EUR': 'EU',
      'VND': 'VN',
      'CNY': 'CN',
      'JPY': 'JP',
      'GBP': 'GB',
      'KRW': 'KR',
      'SGD': 'SG',
      'THB': 'TH',
      'MYR': 'MY',
      'PHP': 'PH',
      'INR': 'IN',
      'AUD': 'AU',
      'CAD': 'CA',
      'HKD': 'HK',
      'NZD': 'NZ',
      'CHF': 'CH',
      'AED': 'AE',
      'SAR': 'SA',
      'LAK': 'LA',
      'KHR': 'KH',
      'MMK': 'MM',
      'BND': 'BN',
      'IDR': 'ID',
    };
    final cc = specialMap[code] ?? code.substring(0, 2);
    return _countryCodeToFlag(cc);
  }

  String _countryCodeToFlag(String countryCode) {
    if (countryCode.length != 2) return '🏳️';
    final base = 0x1F1E6;
    final first = countryCode.codeUnitAt(0) - 0x41 + base;
    final second = countryCode.codeUnitAt(1) - 0x41 + base;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
