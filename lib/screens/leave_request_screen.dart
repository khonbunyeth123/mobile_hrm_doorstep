import 'package:flutter/material.dart';
import '../services/leave_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _selectedLeaveType = 'Sick Leave';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isHalfDay = false;

  final List<String> _leaveTypes = const [
    'Sick Leave',
    'Annual Leave',
    'Personal Leave',
    'Emergency Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Bereavement Leave',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStartDate) async {
    final today = DateTime.now();
    final minDate = isStartDate ? today : (_startDate ?? today);
    final initialDate = isStartDate
        ? (_startDate != null && _startDate!.isAfter(minDate)
              ? _startDate!
              : minDate)
        : (_endDate != null && _endDate!.isAfter(minDate) ? _endDate! : minDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.brand,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStartDate) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      _showMessage('Please select a start date');
      return;
    }
    if (!_isHalfDay && _endDate == null) {
      _showMessage('Please select an end date');
      return;
    }
    if (!_isHalfDay && _endDate!.isBefore(_startDate!)) {
      _showMessage('End date cannot be earlier than start date');
      return;
    }

    setState(() => _isLoading = true);

    final result = await LeaveService.createLeave({
      'leave_type': _selectedLeaveType,
      'start_date': _startDate!.toIso8601String().split('T')[0],
      'end_date': _isHalfDay
          ? _startDate!.toIso8601String().split('T')[0]
          : _endDate!.toIso8601String().split('T')[0],
      'is_half_day': _isHalfDay,
      'reason': _reasonController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted successfully!')),
      );
      Navigator.pop(context);
    } else {
      _showMessage(_extractSubmitError(result));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _extractSubmitError(Map<String, dynamic> result) {
    final message = result['message']?.toString();
    final errors = result['errors'];

    if (errors is Map && errors.isNotEmpty) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first.toString().trim();
          if (first.isNotEmpty) return first;
        }
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    }

    if (message != null && message.trim().isNotEmpty) {
      return message.trim();
    }

    return 'Failed to submit leave request';
  }

  int _calculateLeaveDays() {
    if (_startDate == null) return 0;
    if (_isHalfDay) return 1;
    if (_endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return 'Select date';
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: AppTheme.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(context, date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(22),
      color: Colors.white,
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
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave request',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Submit a clear request in under a minute.',
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
          const AppStatusPill(
            label: 'Easy to scan, easy to submit',
            color: AppTheme.brandDark,
            backgroundColor: AppTheme.brandSoft,
            icon: Icons.auto_awesome_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_startDate == null) return const SizedBox.shrink();
    final days = _calculateLeaveDays();

    return AppSurfaceCard(
      color: AppTheme.brandTint,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppTheme.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Duration: $days day${days == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Request')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                const SizedBox(height: 16),
                const AppSectionHeader(
                  title: 'Request details',
                  subtitle: 'Choose the type, dates, and reason.',
                ),
                const SizedBox(height: 12),
                AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLeaveType,
                        decoration: const InputDecoration(
                          labelText: 'Leave type',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _leaveTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedLeaveType = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isHalfDay,
                        activeThumbColor: AppTheme.brand,
                        title: const Text(
                          'Half-day request',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: const Text(
                          'Use this when you only need a partial day off.',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _isHalfDay = value;
                            if (_isHalfDay) _endDate = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AppSectionHeader(
                  title: 'Dates',
                  subtitle: 'Pick the start date first. End date is optional for half-day.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dateTile(
                        label: 'Start date',
                        date: _startDate,
                        onTap: () => _selectDate(true),
                        icon: Icons.chevron_right_rounded,
                      ),
                    ),
                    if (!_isHalfDay) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateTile(
                          label: 'End date',
                          date: _endDate,
                          onTap: () => _selectDate(false),
                          icon: Icons.chevron_right_rounded,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(),
                if (_startDate != null) const SizedBox(height: 16),
                AppSurfaceCard(
                  child: TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Tell us why you need this leave...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a reason for your leave';
                      }
                      if (value.trim().length < 10) {
                        return 'Please provide a more detailed reason';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'Submit leave request',
                  onPressed: _submitLeaveRequest,
                  loading: _isLoading,
                  icon: Icons.send_rounded,
                ),
                const SizedBox(height: 16),
                AppSurfaceCard(
                  color: AppTheme.accentSoft,
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your request is easier to approve when the reason is specific and the dates are correct before submission.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
