import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/notification_screen.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call once in main() after Firebase.initializeApp()
  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Save to local storage
      await NotificationStorage.add(message);

      // Show in-app banner
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        _showBanner(
          context,
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? '',
          status: message.data['status'] ?? '',
          navigatorKey: navigatorKey,
        );
      }
    });

    // App opened from background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await NotificationStorage.add(message);
      navigatorKey.currentState?.pushNamed('/notifications');
    });

    // App launched from terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await NotificationStorage.add(initialMessage);
      // Delay navigation until app is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed('/notifications');
      });
    }

    // Listen for token refresh and update backend
    _messaging.onTokenRefresh.listen((newToken) async {
      try {
        // Import ApiService if you want auto-refresh on backend
        // await ApiService.post('auth/fcm-token', {'fcm_token': newToken});
      } catch (_) {}
    });
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static void _showBanner(
    BuildContext context, {
    required String title,
    required String body,
    required String status,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    final isApproved = status == 'approved';
    final color = isApproved
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final icon = isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            navigatorKey.currentState?.pushNamed('/notifications');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
