import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationSettings {
  final bool enabled;
  final List<String> selectedHabitIds;
  final List<String> selectedTimes;

  const NotificationSettings({
    this.enabled=false,
    this.selectedHabitIds=const[],
    this.selectedTimes=const[],
  });

  Map<String, dynamic> toJson()=>{
        'enabled': enabled,
        'habitIds': selectedHabitIds,
        'times': selectedTimes,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> j) =>
      NotificationSettings(
        enabled: j['enabled'] as bool? ?? false,
        selectedHabitIds:
            (j['habitIds'] as List<dynamic>?)?.cast<String>() ?? [],
        selectedTimes:
            (j['times'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  NotificationSettings copyWith({
    bool? enabled,
    List<String>? selectedHabitIds,
    List<String>? selectedTimes,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        selectedHabitIds: selectedHabitIds ?? this.selectedHabitIds,
        selectedTimes: selectedTimes ?? this.selectedTimes,
      );
}

class NotificationService {
  static const _settingsKey='notification_settings';
  static final _messaging=FirebaseMessaging.instance;

  static Future<void> init() async {
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);
    }
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          'Foreground FCM: ${message.notification?.title} — ${message.notification?.body}');
    });
  }
  Future<String?> getToken() async {
  try {
    return await _messaging.getToken(
      vapidKey: 'BOiSkdJjfIiHMdfJch3ZlXXtmPQB_Xpfrca4Pvjssv3sfJ_8Wn0XN1gYqQ9NlyXwG7G_8NaHV9FbezgzHcsMMHQ',
    );
  } catch (e) {
    debugPrint('FCM token error: $e');
    return null;
  }
}

  Future<void> subscribeToHabits(
      NotificationSettings settings, List<String> habitNames) async {
    if (kIsWeb) return; 
    for (final name in habitNames) {
      final topic = _toTopic(name);
      await _messaging.unsubscribeFromTopic(topic);
    }
    if (!settings.enabled) return;
    final selectedNames=habitNames; 
    for (final name in selectedNames) {
      await _messaging.subscribeToTopic(_toTopic(name));
    }
  }

  String _toTopic(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  Future<NotificationSettings> loadSettings() async {
    final prefs=await SharedPreferences.getInstance();
    final raw=prefs.getString(_settingsKey);
    if (raw==null) return const NotificationSettings();
    return NotificationSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}
