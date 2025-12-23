import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  const SettingsScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'Tiếng Việt';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'Tiếng Việt';
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> _resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _language = 'Tiếng Việt';
      _isDarkMode = false;
    });

    await context.setLocale(const Locale('vi'));
    widget.onThemeChanged?.call(false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('reset_success'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔸 Ngôn ngữ
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            subtitle: Text(_language),
            trailing: DropdownButton<String>(
              value: _language,
              items: ['Tiếng Việt', 'English'].map(
                (lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(lang),
                  );
                },
              ).toList(),
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _language = value);
                  _saveSettings();

                  if (value == 'Tiếng Việt') {
                    await context.setLocale(const Locale('vi'));
                  } else {
                    await context.setLocale(const Locale('en'));
                  }
                }
              },
            ),
          ),
          const Divider(),

          // 🔸 Độ tin cậy
          ListTile(
            leading: const Icon(Icons.verified_rounded, color: Colors.teal),
            title: Text('app_accuracy'.tr()),
            subtitle: const Text(
              'Ứng dụng đạt độ chính xác trung bình 96%\n(được kiểm thử với bộ dữ liệu tiền tệ Việt Nam).',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const Divider(),

          // 🔸 Dark mode
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: Text('dark_mode'.tr()),
            subtitle: Text(
              _isDarkMode ? 'dark_on'.tr() : 'dark_off'.tr(),
            ),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              _saveSettings();
              widget.onThemeChanged?.call(value);
            },
          ),
          const Divider(),

          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.restore),
              label: Text('reset_default'.tr()),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('confirm'.tr()),
                    content: Text('confirm_reset'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetSettings();
                        },
                        child: Text('agree'.tr()),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
