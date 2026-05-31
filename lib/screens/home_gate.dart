import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../features/admin_calendar/screens/admin_calendar_home_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        if (!isLoggedIn) {
          return const LoginScreen();
        }

        return FutureBuilder<String>(
          future: AuthService.currentRole(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data ?? 'employee';
            if (role.toLowerCase() == 'admin') {
              return const AdminCalendarHomeScreen();
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}
