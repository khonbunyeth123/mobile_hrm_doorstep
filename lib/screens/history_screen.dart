import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _activeDate = DateTime.now();
  
  List<Map<String, dynamic>> _groupedAttendance = [];
  bool _attendanceLoading = true;

  List<dynamic> _leaveRecords = [];
  bool _leaveLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAttendanceHistory();
    _fetchLeaveHistory();
  }

  Future<void> _fetchAttendanceHistory() async {
    setState(() {
      _attendanceLoading = true;
    });
    
    final result = await HistoryService.getAttendanceHistory(
      month: _activeDate.month,
      year: _activeDate.year,
    );
    
    if (!mounted) return;
    setState(() {
      _attendanceLoading = false;
      if (result['success'] == true) {
        _groupAttendance(result['data'] ?? []);
      }
    });
  }

  Future<void> _fetchLeaveHistory() async {
    setState(() {
      _leaveLoading = true;
    });
    final result = await HistoryService.getLeaveHistory();
    if (!mounted) return;
    setState(() {
      _leaveLoading = false;
      if (result['success'] == true) {
        _leaveRecords = result['data']?['leave_applications'] ?? [];
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _activeDate = DateTime(_activeDate.year, _activeDate.month + delta);
    });
    _fetchAttendanceHistory(); 
  }

  void _groupAttendance(List<dynamic> records) {
    final Map<String, List<dynamic>> map = {};
    for (var record in records) {
      final date = record['date']?.toString() ?? 'Unknown';
      map.putIfAbsent(date, () => []).add(record);
    }

    _groupedAttendance = map.entries.map((e) {
      final scans = List<Map<String, dynamic>>.from(e.value);
      scans.sort((a, b) => (a['check_time']?.toString() ?? '').compareTo(b['check_time']?.toString() ?? ''));
      
      return {
        'date': e.key,
        'scans': scans,
        'firstIn': scans.isNotEmpty ? scans.first['check_time']?.toString() ?? '' : '',
        'lastOut': scans.isNotEmpty ? scans.last['check_time']?.toString() ?? '' : '',
      };
    }).toList();
    _groupedAttendance.sort((a, b) => b['date'].compareTo(a['date']));
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return MaterialLocalizations.of(context).formatMediumDate(date);
    } catch (_) { return dateStr; }
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $ampm';
    } catch (_) { return timeStr; }
  }

  String _formatMaybeDate(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(text);
      return MaterialLocalizations.of(context).formatMediumDate(date);
    } catch (_) {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Attendance'), Tab(text: 'Leaves')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              _buildMonthNavigator(),
              Expanded(
                child: _attendanceLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchAttendanceHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _groupedAttendance.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _AttendanceExpansionTile(_groupedAttendance[i], _formatDate, _formatTime),
                      ),
                    ),
              ),
            ],
          ),
          _leaveLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchLeaveHistory,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _leaveRecords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildLeaveItem(_leaveRecords[i]),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
          Text(DateFormat.yMMMM().format(_activeDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  Widget _buildLeaveItem(Map<String, dynamic> record) {
    final status = (record['status']?.toString() ?? record['leave_status']?.toString() ?? 'Pending').toLowerCase();
    final leaveType = record['leave_type']?.toString() ?? record['type']?.toString() ?? 'Leave';
    final startDate = record['start_date'] ?? record['from_date'] ?? record['start_at'] ?? record['leave_from'];
    final endDate = record['end_date'] ?? record['to_date'] ?? record['end_at'] ?? record['leave_to'];
    Color color = AppTheme.warning;
    if (status == 'approved') {
      color = AppTheme.success;
    } else if (status == 'rejected') {
      color = AppTheme.danger;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.event_note_rounded, color: color),
        ),
        title: Text(leaveType, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${_formatMaybeDate(startDate)} - ${_formatMaybeDate(endDate)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _AttendanceExpansionTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(String) formatDate;
  final String Function(String) formatTime;

  const _AttendanceExpansionTile(this.data, this.formatDate, this.formatTime);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(formatDate(data['date']?.toString() ?? ''), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            const Icon(Icons.login, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(formatTime(data['firstIn']?.toString() ?? '')),
            const SizedBox(width: 12),
            const Icon(Icons.logout, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(formatTime(data['lastOut']?.toString() ?? '')),
          ],
        ),
        children: (data['scans'] as List).map((scan) => _buildScanRow(scan)).toList(),
      ),
    );
  }

  Widget _buildScanRow(Map<String, dynamic> scan) {
    final type = scan['check_type_name']?.toString() ?? 'Unknown';
    Color color = AppTheme.brand;
    IconData icon = Icons.circle;

    switch (type) {
      case 'Check-In': color = AppTheme.success; icon = Icons.login; break;
      case 'Break-Out': color = Colors.orange; icon = Icons.coffee; break;
      case 'Break-In': color = Colors.blue; icon = Icons.work; break;
      case 'Check-Out': color = AppTheme.danger; icon = Icons.logout; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(type, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(formatTime(scan['check_time']), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
