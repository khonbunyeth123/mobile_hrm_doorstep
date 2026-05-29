import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _attendanceRecords = [];
  bool _attendanceLoading = true;
  String? _attendanceError;

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

  Future<void> _fetchAttendanceHistory() async {
    setState(() {
      _attendanceLoading = true;
      _attendanceError = null;
    });

    final result = await HistoryService.getAttendanceHistory();
    if (!mounted) return;

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
    if (!mounted) return;

    setState(() {
      _leaveLoading = false;
      if (result['success'] == true) {
        _leaveRecords = result['data']?['leave_applications'] ?? [];
      } else {
        _leaveError = result['message'] ?? 'Failed to load leave history';
      }
    });
  }

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
        return AppTheme.warning;
      case 1:
        return AppTheme.success;
      case 2:
        return AppTheme.danger;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getLeaveStatusBackground(int statusId) {
    switch (statusId) {
      case 0:
        return const Color(0xFFFFF7E6);
      case 1:
        return const Color(0xFFEAFBF2);
      case 2:
        return const Color(0xFFFDECEC);
      default:
        return AppTheme.backgroundAlt;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return MaterialLocalizations.of(context).formatMediumDate(date);
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

  Widget _buildHero() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.brandDark, AppTheme.brand],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.timeline_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review attendance and leave activity in one place.',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniSummary(
                  label: 'Scans',
                  value: _attendanceLoading ? '...' : '${_attendanceRecords.length}',
                  color: AppTheme.brand,
                  icon: Icons.qr_code_scanner_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniSummary(
                  label: 'Leaves',
                  value: _leaveLoading ? '...' : '${_leaveRecords.length}',
                  color: AppTheme.accent,
                  icon: Icons.event_note_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
    required String time,
    required String status,
    required Color statusColor,
    required Color statusBg,
  }) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.brandSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusPill(
                      label: date,
                      color: AppTheme.textSecondary,
                      backgroundColor: AppTheme.backgroundAlt,
                      icon: Icons.calendar_today_rounded,
                    ),
                    AppStatusPill(
                      label: time,
                      color: AppTheme.textSecondary,
                      backgroundColor: AppTheme.backgroundAlt,
                      icon: Icons.schedule_rounded,
                    ),
                    AppStatusPill(
                      label: status,
                      color: statusColor,
                      backgroundColor: statusBg,
                      icon: Icons.verified_rounded,
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

  Widget _buildAttendanceTab() {
    return RefreshIndicator(
      onRefresh: _fetchAttendanceHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          const AppSectionHeader(
            title: 'Attendance',
            subtitle: 'The latest scans are shown first.',
          ),
          const SizedBox(height: 12),
          if (_attendanceLoading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_attendanceError != null)
            AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load attendance history',
              message: _attendanceError!,
              actionLabel: 'Try again',
              onAction: _fetchAttendanceHistory,
            )
          else if (_attendanceRecords.isEmpty)
            const AppEmptyState(
              icon: Icons.qr_code_scanner_rounded,
              title: 'No scan history yet',
              message: 'Your attendance scans will appear here after you check in.',
            )
          else
            ..._attendanceRecords.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHistoryCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: record['check_type_name'] ?? 'Attendance Scan',
                  subtitle: 'Date: ${_formatDate(record['date'])}',
                  date: _formatDate(record['date']),
                  time: _formatTime(record['check_time']),
                  status: 'Success',
                  statusColor: AppTheme.success,
                  statusBg: const Color(0xFFEAFBF2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScansTab() {
    return RefreshIndicator(
      onRefresh: _fetchAttendanceHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          const AppSectionHeader(
            title: 'Scan records',
            subtitle: 'Quick access to the most recent check-ins and check-outs.',
          ),
          const SizedBox(height: 12),
          if (_attendanceLoading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_attendanceError != null)
            AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load scan history',
              message: _attendanceError!,
              actionLabel: 'Retry',
              onAction: _fetchAttendanceHistory,
            )
          else if (_attendanceRecords.isEmpty)
            const AppEmptyState(
              icon: Icons.qr_code_scanner_rounded,
              title: 'No scan records',
              message: 'Use the scanner to create your first attendance record.',
            )
          else
            ..._attendanceRecords.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHistoryCard(
                  icon: Icons.qr_code_rounded,
                  title: record['check_type_name'] ?? 'Scan',
                  subtitle: 'Attendance recorded successfully',
                  date: _formatDate(record['date']),
                  time: _formatTime(record['check_time']),
                  status: 'Completed',
                  statusColor: AppTheme.brand,
                  statusBg: AppTheme.brandSoft,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeavesTab() {
    final pendingCount = _leaveRecords.where((r) => (r['status_id'] ?? 0) == 0).length;
    final approvedCount = _leaveRecords.where((r) => (r['status_id'] ?? 0) == 1).length;

    return RefreshIndicator(
      onRefresh: _fetchLeaveHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.brandDark, AppTheme.brand],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.event_note_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave history',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'See what is pending, approved, or rejected at a glance.',
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniSummary(
                        label: 'Total',
                        value: _leaveLoading ? '...' : '${_leaveRecords.length}',
                        color: AppTheme.brand,
                        icon: Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniSummary(
                        label: 'Approved',
                        value: approvedCount.toString(),
                        color: AppTheme.success,
                        icon: Icons.verified_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniSummary(
                        label: 'Pending',
                        value: pendingCount.toString(),
                        color: AppTheme.warning,
                        icon: Icons.hourglass_top_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionHeader(
            title: 'Requests',
            subtitle: 'Track every leave request with status and dates.',
          ),
          const SizedBox(height: 12),
          if (_leaveLoading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_leaveError != null)
            AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load leave history',
              message: _leaveError!,
              actionLabel: 'Retry',
              onAction: _fetchLeaveHistory,
            )
          else if (_leaveRecords.isEmpty)
            const AppEmptyState(
              icon: Icons.event_note_rounded,
              title: 'No leave requests yet',
              message: 'Submitted leave requests will show up here once they are created.',
            )
          else
            ..._leaveRecords.map((record) {
              final statusId = record['status_id'] ?? 0;
              final days = _calculateDays(record['start_date'], record['end_date']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHistoryCard(
                  icon: Icons.event_available_rounded,
                  title: record['leave_type'] ?? 'Leave',
                  subtitle:
                      '${record['reason'] ?? ''}${record['reason'] == null || record['reason'].toString().isEmpty ? '' : '\n'}$days day${days == 1 ? '' : 's'}',
                  date: _formatDate(record['start_date']),
                  time: _formatDate(record['created_at']),
                  status: _getLeaveStatus(statusId),
                  statusColor: _getLeaveStatusColor(statusId),
                  statusBg: _getLeaveStatusBackground(statusId),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
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
          _buildAttendanceTab(),
          _buildScansTab(),
          _buildLeavesTab(),
        ],
      ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniSummary({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
