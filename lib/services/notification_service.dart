// lib/services/notification_service.dart

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:z_emp/providers/notifications_provider.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin? _localNotificationsPlugin;

  // Reference to the NotificationsProvider (will be set during initialization)
  NotificationsProvider? _notificationsProvider;

  // List of topics to subscribe to
  final List<String> _topics = [
    "announcements",
    "attendanceRecords",
    "chats",
    "enquiries",
    "leaveRequests",
    "products",
    "salaryAdvances",
    "tasks",
  ];

  Future<void> initNotifications({BuildContext? context}) async {
    try {
      print("Initializing notification service...");

      // Get the notifications provider if context is available
      if (context != null) {
        try {
          _notificationsProvider =
              Provider.of<NotificationsProvider>(context, listen: false);
          print(
              'NotificationsProvider connected. Push enabled: ${_notificationsProvider?.enablePush}');
        } catch (e) {
          print('Error getting NotificationsProvider: $e');
        }
      }

      // If push notifications are disabled, don't proceed with FCM setup
      if (_notificationsProvider != null &&
          !_notificationsProvider!.enablePush) {
        print(
            'Push notifications are disabled in settings. Skipping FCM setup.');
        return;
      }

      // Request notification permissions (iOS & Android)
      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
        try {
          NotificationSettings settings = await _messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          print(
              'User notification permission status: ${settings.authorizationStatus}');
        } catch (e) {
          print('Error requesting notification permissions: $e');
        }
      }

      // For Windows, we need to use local notifications only
      if (kIsWeb ||
          Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS) {
        print("Setting up notifications for desktop platform");

        // Firebase Messaging has limited support on desktop platforms
        // We'll still try to get a token for cross-platform compatibility
        try {
          final token = await _messaging.getToken();
          print('FCM Token (may not work on all desktop platforms): $token');
        } catch (e) {
          print('Could not get FCM token on desktop: $e');
        }
      }

      // Initialize local notifications
      try {
        _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

        if (Platform.isAndroid) {
          // Android-specific initialization
          const AndroidInitializationSettings initializationSettingsAndroid =
              AndroidInitializationSettings('@mipmap/ic_launcher');
          const InitializationSettings initializationSettings =
              InitializationSettings(android: initializationSettingsAndroid);

          await _localNotificationsPlugin?.initialize(
            initializationSettings,
            onDidReceiveNotificationResponse:
                (NotificationResponse response) async {
              print('Notification tapped: ${response.payload}');
            },
          );
        } else if (Platform.isIOS) {
          // iOS initialization
          final DarwinInitializationSettings initializationSettingsDarwin =
              DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );
          final InitializationSettings initializationSettings =
              InitializationSettings(
            iOS: initializationSettingsDarwin,
          );

          await _localNotificationsPlugin?.initialize(
            initializationSettings,
            onDidReceiveNotificationResponse:
                (NotificationResponse response) async {
              print('Notification tapped: ${response.payload}');
            },
          );
        }
      } catch (e) {
        print('Error initializing local notifications: $e');
        // Continue without local notifications
      }

      // Subscribe to each topic
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        for (final topic in _topics) {
          try {
            await _messaging.subscribeToTopic(topic);
            print('Subscribed to topic: $topic');
          } catch (e) {
            print('Error subscribing to topic $topic: $e');
          }
        }
      }

      // Listen for foreground messages and display them as local notifications
      try {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Received message in foreground: ${message.messageId}');
          _showNotification(message);
        });

        // Handle messages opened from terminated state
        final initialMessage =
            await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          print('App opened from terminated state via notification');
          _handleNotificationAction(initialMessage);
        }

        // Optionally handle onMessageOpenedApp (when user taps the notification)
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('Message opened from background state');
          _handleNotificationAction(message);
        });
      } catch (e) {
        print('Error setting up message listeners: $e');
      }

      print("Notification service initialized successfully");
    } catch (e, stackTrace) {
      print('Error initializing notifications: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _handleNotificationAction(RemoteMessage message) {
    // Here you would handle any navigation or actions when a notification is tapped
    print('Handling notification action for: ${message.messageId}');
    // Example: Navigate to a specific screen based on the notification data
  }

  void _showNotification(RemoteMessage message) {
    try {
      // Skip if local notifications plugin is not initialized
      if (_localNotificationsPlugin == null) {
        print('Local notifications plugin not initialized');
        return;
      }

      // Check if notifications are enabled in user settings
      if (_notificationsProvider != null &&
          !_notificationsProvider!.enablePush) {
        print(
            'Push notifications are disabled in settings. Not showing notification.');
        return;
      }

      // Extract notification details from the message
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        print('Showing local notification: ${notification.title}');

        // Check sound settings
        bool playSound = _notificationsProvider?.soundAndVibration ?? true;

        _localNotificationsPlugin?.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // channel ID
              'High Importance Notifications', // channel name
              channelDescription:
                  'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              playSound: playSound,
              enableVibration: playSound,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: playSound,
            ),
          ),
          payload:
              message.data['route'] ?? 'Default_Route', // optional payload data
        );
      } else {
        print('No notification content in the message');
      }
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      print('FCM Registration Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Method to update settings after they've changed
  void updateSettings(NotificationsProvider provider) {
    _notificationsProvider = provider;
    print(
        'Notification settings updated. Push enabled: ${provider.enablePush}');
  }
}
