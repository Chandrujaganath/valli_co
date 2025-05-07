// lib/widgets/main_scaffold.dart
// ignore_for_file: library_private_types_in_public_api

import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../screens/messaging/messaging_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/home/home_screen.dart';
import '../l10n/app_localizations.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({super.key, this.initialIndex = 1});

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Messaging
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Settings
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) {
      // If already on the tab, pop to the first route of that tab.
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          Widget child;
          switch (index) {
            case 0:
              child = const MessagingScreen();
              break;
            case 1:
              child = const HomeScreen();
              break;
            case 2:
              child = const SettingsScreen();
              break;
            default:
              child = Container();
          }
          return MaterialPageRoute(builder: (context) => child);
        },
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Check if the current Navigator can pop a route.
    final currentNavigator = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    } else {
      // If there is no route to pop, show a confirmation dialog before exiting.
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Exit'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _buildOffstageNavigator(0),
            _buildOffstageNavigator(1),
            _buildOffstageNavigator(2),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(bottom: 1.0),
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? const LinearGradient(
                      colors: [
                        Color(0x99000000), // 60% black
                        Color(0x1A000000), // 10% black
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [
                        Color(0xB3FFFFFF), // 70% white
                        Color(0x4DFFFFFF), // 30% white
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: SalomonBottomBar(
                  currentIndex: _currentIndex,
                  onTap: _onItemTapped,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: theme.colorScheme.primary,
                  unselectedItemColor:
                      theme.bottomNavigationBarTheme.unselectedItemColor,
                  items: [
                    SalomonBottomBarItem(
                      icon: const Icon(Icons.message),
                      title: Text(
                        appLocalization?.translate('messaging') ?? 'Messaging',
                      ),
                      selectedColor: theme.colorScheme.primary,
                      unselectedColor:
                          theme.bottomNavigationBarTheme.unselectedItemColor,
                    ),
                    SalomonBottomBarItem(
                      icon: const Icon(Icons.home),
                      title: Text(
                        appLocalization?.translate('home') ?? 'Home',
                      ),
                      selectedColor: theme.colorScheme.primary,
                      unselectedColor:
                          theme.bottomNavigationBarTheme.unselectedItemColor,
                    ),
                    SalomonBottomBarItem(
                      icon: const Icon(Icons.settings),
                      title: Text(
                        appLocalization?.translate('settings_tab') ?? 'Settings',
                      ),
                      selectedColor: theme.colorScheme.primary,
                      unselectedColor:
                          theme.bottomNavigationBarTheme.unselectedItemColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
