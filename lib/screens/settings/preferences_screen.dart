// lib/screens/settings/preferences_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:z_emp/l10n/app_localizations.dart';
import 'package:z_emp/providers/locale_provider.dart';
import 'package:z_emp/providers/theme_provider.dart';
import 'package:z_emp/widgets/glassmorphic_container.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text(
          loc?.translate('preferences') ?? 'Preferences',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      child: Container(
        decoration: _buildBackground(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassmorphicContainer(
                borderRadius: 20,
                blur: 10,
                opacity: 0.2,
                child: Column(
                  children: [
                    // Theme Switch
                    _buildToggleRow(
                      context,
                      title: loc?.translate('dark_mode') ?? 'Dark Mode',
                      value: themeProvider.isDarkMode,
                      onChanged: (val) => themeProvider.toggleTheme(val),
                    ),
                    const Divider(),
                    // Language selection
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(loc?.translate('language') ?? 'Language'),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              _showLanguageActionSheet(context, localeProvider);
                            },
                            child: Text(
                              localeProvider.locale.languageCode.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Font Size
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(loc?.translate('font_size') ?? 'Font Size'),
                          ),
                          // A sample: Large/Default/Small
                          CupertinoButton(
                            onPressed: () {
                              // Show some font size selection
                              // Could be an ActionSheet or custom slider
                            },
                            child: const Text('Default', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Layout modifications
                    _buildToggleRow(
                      context,
                      title: loc?.translate('compact_layout') ?? 'Compact Layout',
                      value: false, // manage state in your provider or local state
                      onChanged: (val) {
                        // implement logic to switch layout mode
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageActionSheet(BuildContext context, LocaleProvider localeProvider) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Select Language'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              localeProvider.setLocale(const Locale('en'));
            },
            child: const Text('English'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              localeProvider.setLocale(const Locale('ta'));
            },
            child: const Text('Tamil'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CupertinoFormRow(
      prefix: Text(title),
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  BoxDecoration _buildBackground() {
  return const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

}
