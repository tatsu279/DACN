import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/currency_info.dart';

class CurrencyLookupScreen extends StatefulWidget {
  final String? selectedCode;
  const CurrencyLookupScreen({super.key, this.selectedCode});

  @override
  State<CurrencyLookupScreen> createState() => _CurrencyLookupScreenState();
}

class _CurrencyLookupScreenState extends State<CurrencyLookupScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final entries = currencyDescriptions.entries.toList();

    final filteredList = entries.where((entry) {
      final code = entry.key.toLowerCase();
      final desc = entry.value.toLowerCase();
      return code.contains(_searchQuery.toLowerCase()) ||
          desc.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('select_currency'.tr()),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // 📋 Result list
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      'no_result'.tr(),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final code = filteredList[index].key;
                      final desc = filteredList[index].value;
                      final flag = _getFlagEmoji(code);

                      final match = RegExp(r'\((.*?)\)').firstMatch(desc);
                      final country = match != null
                          ? match.group(1)!
                          : tr("unknown_country");
                      final name = desc.split('(').first.trim();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            child: Text(
                              flag,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          title: Text(
                            '$code – $name',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text("${'country'.tr()}: $country"),
                          trailing: widget.selectedCode == code
                              ? const Icon(Icons.check_circle,
                                  color: Colors.teal)
                              : null,
                          onTap: () {
                            Navigator.pop(context, code);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 🇻🇳 Flag emoji
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

    final countryCode = specialMap[code] ?? code.substring(0, 2);
    return _countryCodeToFlag(countryCode);
  }

  /// 🇨🇳 Country code → flag emoji
  String _countryCodeToFlag(String countryCode) {
    if (countryCode.length != 2) return '🏳️';
    final base = 0x1F1E6;
    final first = countryCode.codeUnitAt(0) - 0x41 + base;
    final second = countryCode.codeUnitAt(1) - 0x41 + base;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
