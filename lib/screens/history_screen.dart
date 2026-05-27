// ============================================================
//  lib/screens/history_screen.dart
//  History screen — fetches real data from API
// ============================================================

import 'package:flutter/material.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ─── Attendance state ────────────────────────────────────
  List<dynamic> _attendanceRecords = [];
  bool _attendanceLoading = true;
  String? _attendanceError;

  // ─── Leave state ─────────────────────────────────────────
  List<dynamic> _leaveRecords = [];
  bool _leaveLoading = true;
  String? _leaveError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAttendanceHistory();
    _fetchLeaveHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Fetch Data ───────────────────────────────────────────

  Future<void> _fetchAttendanceHistory() async {
    setState(() {
      _attendanceLoading = true;
      _attendanceError = null;
    });
    final result = await HistoryService.getAttendanceHistory();
    setState(() {
      _attendanceLoading = false;
      if (result['success'] == true) {
        _attendanceRecords = result['data'] ?? [];
      } else {
        _attendanceError =
            result['message'] ?? 'Failed to load attendance history';
      }
    });
  }

  Future<void> _fetchLeaveHistory() async {
    setState(() {
      _leaveLoading = true;
      _leaveError = null;
    });
    final result = await HistoryService.getLeaveHistory();
    setState(() {
      _leaveLoading = false;
      if (result['success'] == true) {
        _leaveRecords = result['data']?['leave_applications'] ?? [];
      } else {
        _leaveError = result['message'] ?? 'Failed to load leave history';
      }
    });
  }

  // ─── Helpers ──────────────────────────────────────────────

  String _getLeaveStatus(int statusId) {
    switch (statusId) {
      case 0:
        return 'Pending';
      case 1:
        return 'Approved';
      case 2:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  Color _getLeaveStatusColor(int statusId) {
    switch (statusId) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '-';
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $ampm';
    } catch (_) {
      return timeStr;
    }
  }

  int _calculateDays(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 1;
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 1;
    }
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Scans'),
            Tab(text: 'Leaves'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllHistoryTab(),
          _buildScansHistoryTab(),
          _buildLeavesHistoryTab(),
        ],
      ),
    );
  }

  // ─── All Tab ──────────────────────────────────────────────

  Widget _buildAllHistoryTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchAttendanceHistory();
        await _fetchLeaveHistory();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.qr_code_scanner,
                    title: 'Total Scans',
                    value: _attendanceLoading
                        ? '...'
                        : '${_attendanceRecords.length}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.event_note,
                    title: 'Leave Requests',
                    value: _leaveLoading ? '...' : '${_leaveRecords.length}',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Recent Scans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),

            if (_attendanceLoading)
              const Center(child: CircularProgressIndicator())
            else if (_attendanceError != null)
              _buildErrorWidget(_attendanceError!, _fetchAttendanceHistory)
            else if (_attendanceRecords.isEmpty)
              _buildEmptyWidget('No scan records found')
            else
              ..._attendanceRecords
                  .take(3)
                  .map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHistoryItem(
                        icon: Icons.qr_code,
                        title: record['check_type_name'] ?? 'Attendance Scan',
                        subtitle: 'Date: ${_formatDate(record['date'])}',
                        date: _formatDate(record['date']),
                        time: _formatTime(record['check_time']),
                        status: 'Success',
                        statusColor: Colors.blue,
                      ),
                    ),
                  ),

            const SizedBox(height: 24),

            Text(
              'Recent Leaves',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),

            if (_leaveLoading)
              const Center(child: CircularProgressIndicator())
            else if (_leaveError != null)
              _buildErrorWidget(_leaveError!, _fetchLeaveHistory)
            else if (_leaveRecords.isEmpty)
              _buildEmptyWidget('No leave records found')
            else
              ..._leaveRecords.take(3).map((record) {
                final statusId = record['status_id'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHistoryItem(
                    icon: Icons.event_note,
                    title: record['leave_type'] ?? 'Leave',
                    subtitle: record['reason'] ?? '',
                    date: _formatDate(record['start_date']),
                    time: _formatDate(record['created_at']),
                    status: _getLeaveStatus(statusId),
                    statusColor: _getLeaveStatusColor(statusId),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ─── Scans Tab ────────────────────────────────────────────

  Widget _buildScansHistoryTab() {
    return RefreshIndicator(
      onRefresh: _fetchAttendanceHistory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'QR Code Scans',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total Scans: ${_attendanceLoading ? '...' : _attendanceRecords.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Scan History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            if (_attendanceLoading)
              const Center(child: CircularProgressIndicator())
            else if (_attendanceError != null)
              _buildErrorWidget(_attendanceError!, _fetchAttendanceHistory)
            else if (_attendanceRecords.isEmpty)
              _buildEmptyWidget('No scan records found')
            else
              ..._attendanceRecords.map(
                (record) => _buildScanHistoryItem(
                  checkType: record['check_type_name'] ?? 'Scan',
                  date: _formatDate(record['date']),
                  time: _formatTime(record['check_time']),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Leaves Tab ───────────────────────────────────────────

  Widget _buildLeavesHistoryTab() {
    final pendingCount = _leaveRecords
        .where((r) => (r['status_id'] ?? 0) == 0)
        .length;
    final approvedCount = _leaveRecords
        .where((r) => (r['status_id'] ?? 0) == 1)
        .length;

    return RefreshIndicator(
      onRefresh: _fetchLeaveHistory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.event_note, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Leave Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total: ${_leaveLoading ? '...' : _leaveRecords.length}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              'Approved: $approvedCount',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending: $pendingCount',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Leave History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            if (_leaveLoading)
              const Center(child: CircularProgressIndicator())
            else if (_leaveError != null)
              _buildErrorWidget(_leaveError!, _fetchLeaveHistory)
            else if (_leaveRecords.isEmpty)
              _buildEmptyWidget('No leave records found')
            else
              ..._leaveRecords.map((record) {
                final statusId = record['status_id'] ?? 0;
                final days = _calculateDays(
                  record['start_date'],
                  record['end_date'],
                );
                final startDate = _formatDate(record['start_date']);
                final endDate = _formatDate(record['end_date']);
                final dateRange = record['start_date'] == record['end_date']
                    ? startDate
                    : '$startDate - $endDate';
                return _buildLeaveHistoryItem(
                  type: record['leave_type'] ?? 'Leave',
                  dates: dateRange,
                  days: '$days ${days == 1 ? 'day' : 'days'}',
                  reason: record['reason'] ?? '',
                  status: _getLeaveStatus(statusId),
                  statusColor: _getLeaveStatusColor(statusId),
                  appliedDate: _formatDate(record['created_at']),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ─── Reusable Widgets ─────────────────────────────────────

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $time',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistoryItem({
    required String checkType,
    required String date,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.qr_code, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkType,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $time',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Success',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveHistoryItem({
    required String type,
    required String dates,
    required String days,
    required String reason,
    required String status,
    required Color statusColor,
    required String appliedDate,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.event_note, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dates ($days)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Applied: $appliedDate',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
