import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class NotificationStorage {
  static const _key = 'local_notifications';

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      map['id'] = e.hashCode.toString();
      return map;
    }).toList().reversed.toList();
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

  static Future<int> unreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).where((n) => n['read'] == false).length;
  }

  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final updated = raw.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      if (e.hashCode.toString() == id) map['read'] = true;
      return jsonEncode(map);
    }).toList();
    await prefs.setStringList(_key, updated);
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final updated = raw.where((e) => e.hashCode.toString() != id).toList();
    await prefs.setStringList(_key, updated);
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
    final items = await NotificationStorage.getAll();
    if (!mounted) return;
    setState(() {
      _notifications = items;
      _loading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupNotifications() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<Map<String, dynamic>>>{
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (var n in _notifications) {
      final dt = DateTime.parse(n['time']);
      final date = DateTime(dt.year, dt.month, dt.day);

      if (date == today) groups['Today']!.add(n);
      else if (date == yesterday) groups['Yesterday']!.add(n);
      else groups['Earlier']!.add(n);
    }
    return groups..removeWhere((k, v) => v.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupNotifications();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              await NotificationStorage.clearAll();
              _load();
            },
          )
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty 
          ? const AppEmptyState(icon: Icons.notifications_off_rounded, title: 'No notifications', message: 'You are all caught up!')
          : ListView(
              children: groups.entries.map((group) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(group.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textSecondary)),
                  ),
                  ...group.value.map((n) => _NotificationTile(n, _load)),
                ],
              )).toList(),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> n;
  final VoidCallback onRefresh;
  const _NotificationTile(this.n, this.onRefresh);

  @override
  Widget build(BuildContext context) {
    final isRead = n['read'] as bool;
    final status = n['status'] as String? ?? '';
    
    Color statusColor = AppTheme.brand;
    if (status == 'approved') statusColor = AppTheme.success;
    else if (status == 'rejected') statusColor = AppTheme.danger;

    return Dismissible(
      key: Key(n['id']),
      direction: DismissDirection.endToStart,
      background: Container(color: AppTheme.danger, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) async { await NotificationStorage.delete(n['id']); onRefresh(); },
      child: ListTile(
        tileColor: isRead ? null : AppTheme.brandSoft.withValues(alpha: 0.1),
        leading: Icon(Icons.circle, size: 10, color: isRead ? Colors.transparent : AppTheme.brand),
        title: Text(n['title'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(n['body'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            if (status.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              )
          ],
        ),
        trailing: Text(DateFormat('h:mm a').format(DateTime.parse(n['time'])), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        onTap: () async { await NotificationStorage.markAsRead(n['id']); onRefresh(); },
      ),
    );
  }
}
