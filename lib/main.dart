import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_gate.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/menu_scan_screen.dart';
import 'screens/leave_request_screen.dart';
import 'screens/history_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'features/admin_calendar/screens/admin_calendar_home_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationStorage.add(message);
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.init(navigatorKey);
  ApiService.listenFcmTokenRefresh();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'HRM Doorstep',
      theme: AppTheme.lightTheme(),
      scrollBehavior: const AppScrollBehavior(),
      home: const HomeGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeGate(),
        '/menu-scan': (context) => const MenuScanScreen(),
        '/leave-request': (context) => const LeaveRequestScreen(),
        '/history': (context) => const HistoryScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/admin-calendar': (context) => const AdminCalendarHomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
