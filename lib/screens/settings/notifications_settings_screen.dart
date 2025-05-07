// lib/screens/settings/notifications_settings_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:z_emp/l10n/app_localizations.dart';
import 'package:z_emp/providers/notifications_provider.dart';
import 'package:z_emp/services/notification_service.dart';
import 'package:z_emp/widgets/glassmorphic_container.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final notificationsProvider = Provider.of<NotificationsProvider>(context);
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
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
          loc?.translate('notifications') ?? 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GlassmorphicContainer(
              borderRadius: 20,
              blur: 15,
              opacity: 0.2,
              child: Column(
                children: [
                  _buildToggleRow(
                    context,
                    title: loc?.translate('push_notifications') ??
                        'Push Notifications',
                    value: notificationsProvider.enablePush,
                    onChanged: (val) {
                      notificationsProvider.enablePush = val;
                      notificationService.updateSettings(notificationsProvider);
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  _buildToggleRow(
                    context,
                    title: loc?.translate('sound_vibration') ??
                        'Sound & Vibration',
                    value: notificationsProvider.soundAndVibration,
                    onChanged: (val) {
                      notificationsProvider.soundAndVibration = val;
                      notificationService.updateSettings(notificationsProvider);
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  _buildToggleRow(
                    context,
                    title: loc?.translate('In-App Alerts') ?? 'In-App Alerts',
                    value: notificationsProvider.inAppAlerts,
                    onChanged: (val) {
                      notificationsProvider.inAppAlerts = val;
                      notificationService.updateSettings(notificationsProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
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
      prefix: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
