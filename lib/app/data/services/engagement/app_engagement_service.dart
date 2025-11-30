import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_new_badger/flutter_new_badger.dart';

// Service to track app usage and send engagement reminders
class AppEngagementService {
  static const String _lastOpenedKey = 'last_opened_timestamp';
  static const String _dailyCheckTaskName = 'dailyEngagementCheck';
  
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  // Initialize the service
  Future<void> initialize() async {
    await _initializeNotifications();
    await _initializeWorkManager();
    await recordAppOpen();
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
    
    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Initialize background work manager
  Future<void> _initializeWorkManager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    // Schedule periodic check (every 6 hours)
    await Workmanager().registerPeriodicTask(
      _dailyCheckTaskName,
      _dailyCheckTaskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }

  // Record when app is opened
  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastOpenedKey, DateTime.now().millisecondsSinceEpoch);
    
    // Clear badge when app is opened
    await _clearBadge();
  }

  // Check if app hasn't been opened in 24 hours
  Future<bool> isAppNeglected() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpened = prefs.getInt(_lastOpenedKey);
    
    if (lastOpened == null) return false;
    
    final lastOpenedDate = DateTime.fromMillisecondsSinceEpoch(lastOpened);
    final hoursSinceOpen = DateTime.now().difference(lastOpenedDate).inHours;
    
    return hoursSinceOpen >= 24;
  }

  // Get hours since last open
  Future<int> getHoursSinceLastOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpened = prefs.getInt(_lastOpenedKey);
    
    if (lastOpened == null) return 0;
    
    final lastOpenedDate = DateTime.fromMillisecondsSinceEpoch(lastOpened);
    return DateTime.now().difference(lastOpenedDate).inHours;
  }

  // Send notification reminder
  Future<void> sendEngagementNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'engagement_channel',
      'Farm Engagement',
      channelDescription: 'Reminders to check your farm',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      0,
      '🌾 Your Farm Needs You!',
      'It\'s been 24 hours since you checked on your farm. Come back and manage your crops!',
      details,
    );
  }

  // Set app badge count
  Future<void> _setBadge(int count) async {
    try {
      await FlutterNewBadger.setBadge(count);
    } catch (e) {
      debugPrint('Error setting badge: $e');
    }
  }

  // Clear app badge
  Future<void> _clearBadge() async {
    try {
      await FlutterNewBadger.removeBadge();
    } catch (e) {
      debugPrint('Error clearing badge: $e');
    }
  }

  // Check and update engagement status
  Future<void> checkEngagementStatus() async {
    if (await isAppNeglected()) {
      await sendEngagementNotification();
      await _setBadge(1); // Show badge indicator
    }
  }
}

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final service = AppEngagementService();
      await service.checkEngagementStatus();
    } catch (e) {
      debugPrint('Background task error: $e');
    }
    return Future.value(true);
  });
}

// Widget to show "sad" status banner
class SadFarmIndicator extends StatelessWidget {
  final int hoursSinceLastOpen;
  final VoidCallback? onDismiss;
  
  const SadFarmIndicator({
    Key? key,
    required this.hoursSinceLastOpen,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hoursSinceLastOpen < 24) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade100, Colors.red.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.agriculture,
              color: Colors.red.shade700,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sentiment_dissatisfied,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your farm was lonely!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'You haven\'t checked in for ${hoursSinceLastOpen} hours. '
                  'Your crops need attention!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade400),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}