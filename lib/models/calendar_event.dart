import 'package:flutter/material.dart';

class CalendarEvent {
  final DateTime date;
  final String type; // 'leave' or 'attendance'
  final String title;
  final String status; // 'pending', 'approved', 'rejected' or 'present', 'late', 'absent'
  final Color color;

  CalendarEvent({
    required this.date,
    required this.type,
    required this.title,
    required this.status,
    required this.color,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      date: DateTime.parse(json['date']),
      type: json['type'],
      title: json['title'],
      status: json['status'],
      color: _parseColor(json['color_code']),
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    if (hex.startsWith('#')) {
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (_) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }
}
