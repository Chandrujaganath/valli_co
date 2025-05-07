// lib/screens/settings/settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:z_emp/auth/auth_service.dart';
import 'package:z_emp/l10n/app_localizations.dart';
import 'package:z_emp/providers/locale_provider.dart';
import 'package:z_emp/providers/theme_provider.dart';
import 'package:z_emp/screens/settings/notifications_settings_screen.dart';
import 'package:z_emp/screens/settings/profile_page.dart';
import 'package:z_emp/widgets/glassmorphic_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut(context);

    // Check if the BuildContext is still valid before using it
    if (!context.mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const backgroundGradient = LinearGradient(
      colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.white.withOpacity(0.2),
        border: null,
        middle: Text(
          appLocalization?.translate('settings') ?? 'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(gradient: backgroundGradient),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Profile Tile
              GlassmorphicContainer(
                borderRadius: 20,
                blur: 15,
                opacity: 0.2,
                child: ListTile(
                  leading:
                      const Icon(CupertinoIcons.person_crop_circle, size: 28),
                  title: Text(
                    appLocalization?.translate('profile') ?? 'Profile',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  trailing: const Icon(CupertinoIcons.forward, size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Notifications Tile
              GlassmorphicContainer(
                borderRadius: 20,
                blur: 15,
                opacity: 0.2,
                child: ListTile(
                  leading: const Icon(CupertinoIcons.bell_solid, size: 28),
                  title: Text(
                    appLocalization?.translate('notifications') ??
                        'Notifications',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  trailing: const Icon(CupertinoIcons.forward, size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                          builder: (_) => const NotificationsSettingsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Dark Mode Toggle
              GlassmorphicContainer(
                borderRadius: 20,
                blur: 15,
                opacity: 0.2,
                child: CupertinoFormRow(
                  prefix: Text(
                    appLocalization?.translate('Dark Mode') ?? 'Dark Mode',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return CupertinoSwitch(
                        value: themeProvider.isDarkMode,
                        onChanged: (val) => themeProvider.toggleTheme(val),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Language Selection
              GlassmorphicContainer(
                borderRadius: 20,
                blur: 15,
                opacity: 0.2,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          appLocalization?.translate('language') ?? 'Language',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      Consumer<LocaleProvider>(
                        builder: (context, localeProvider, _) {
                          return CupertinoButton(
                            onPressed: () => _showLanguageActionSheet(
                                context, localeProvider),
                            child: Text(
                              localeProvider.locale.languageCode.toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Logout Tile
              GlassmorphicContainer(
                borderRadius: 20,
                blur: 15,
                opacity: 0.15,
                child: ListTile(
                  leading: const Icon(CupertinoIcons.square_arrow_right,
                      size: 28, color: Colors.redAccent),
                  title: Text(
                    appLocalization?.translate('logout') ?? 'Logout',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () => _handleSignOut(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageActionSheet(
      BuildContext context, LocaleProvider localeProvider) {
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
}
