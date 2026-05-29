import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

/// Stores notifications in SharedPreferences so they survive app restarts.
class NotificationStorage {
  static const _key = 'local_notifications';

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  static Future<void> add(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];

    final entry = jsonEncode({
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'type': message.data['type'] ?? '',
      'status': message.data['status'] ?? '',
      'time': DateTime.now().toIso8601String(),
      'read': false,
    });

    existing.add(entry);
    if (existing.length > 50) existing.removeAt(0);

    await prefs.setStringList(_key, existing);
  }

  static Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final updated = raw.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      map['read'] = true;
      return jsonEncode(map);
    }).toList();
    await prefs.setStringList(_key, updated);
  }

  static Future<int> unreadCount() async {
    final all = await getAll();
    return all.where((n) => n['read'] == false).length;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await NotificationStorage.markAllRead();
    final items = await NotificationStorage.getAll();
    if (!mounted) return;
    setState(() {
      _notifications = items;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    await NotificationStorage.clearAll();
    if (!mounted) return;
    setState(() => _notifications = []);
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return MaterialLocalizations.of(context).formatMediumDate(dt);
    } catch (_) {
      return '';
    }
  }

  Widget _buildHeader() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.brandDark, AppTheme.brand],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.notifications_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep track of leave updates and important alerts.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const AppEmptyState(
      icon: Icons.notifications_none_rounded,
      title: 'No notifications yet',
      message: 'You’ll see approvals, rejections, and updates here as they arrive.',
    );
  }

  Widget _buildCard(Map<String, dynamic> notification) {
    final status = notification['status'] as String? ?? '';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    final accentColor = isApproved
        ? AppTheme.success
        : isRejected
            ? AppTheme.danger
            : AppTheme.brand;
    final bgColor = isApproved
        ? const Color(0xFFEAFBF2)
        : isRejected
            ? const Color(0xFFFDECEC)
            : AppTheme.brandSoft;
    final iconData = isApproved
        ? Icons.check_circle_rounded
        : isRejected
            ? Icons.cancel_rounded
            : Icons.notifications_rounded;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(iconData, color: accentColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] as String? ?? 'Notification',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['body'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusPill(
                      label: status.isEmpty ? 'Update' : status.toUpperCase(),
                      color: accentColor,
                      backgroundColor: bgColor,
                      icon: Icons.bolt_rounded,
                    ),
                    AppStatusPill(
                      label: _formatTime(notification['time'] as String? ?? ''),
                      color: AppTheme.textSecondary,
                      backgroundColor: AppTheme.backgroundAlt,
                      icon: Icons.schedule_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  const AppSectionHeader(
                    title: 'Recent activity',
                    subtitle: 'Tap refresh if you expect a new update.',
                  ),
                  const SizedBox(height: 12),
                  if (_notifications.isEmpty)
                    _buildEmpty()
                  else
                    ..._notifications.map(
                      (notification) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildCard(notification),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
