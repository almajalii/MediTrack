import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/screens/main/settings/settings.dart';
import 'package:meditrack/screens/main/home/notifications_screen.dart';
import 'package:meditrack/services/notification_service.dart';
import 'package:meditrack/bloc/theme_bloc/theme_bloc.dart';
import 'package:meditrack/style/colors.dart';

class MyAppBar {
  static PreferredSizeWidget build(BuildContext context, VoidCallback onNotificationPressed) {
    final user = FirebaseAuth.instance.currentUser;
    final themeState = context.watch<ThemeBloc>().state;
    final notificationService = NotificationService();

    return AppBar(
      title: SizedBox(height: 70, width: 70, child: Image.asset('images/1.png')),
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
        },
        icon: const Icon(Icons.settings),
      ),
      actions: [
        // Notification Bell with Count Badge
        if (user != null)
          StreamBuilder<int>(
            stream: notificationService.getUnreadCount(user.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      // Navigate to notifications screen
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                    },
                    icon: Icon(
                      unreadCount > 0 ? Icons.notifications_active : Icons.notifications_outlined,
                      color: unreadCount > 0 ? Colors.white : null,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient:
              themeState.isDarkMode
                  ? const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)])
                  : const LinearGradient(
                    colors: [AppColors.darkBlue, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        ),
      ),
    );
  }
}
