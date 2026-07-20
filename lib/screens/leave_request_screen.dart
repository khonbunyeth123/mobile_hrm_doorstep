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
  DateTimeRange? _dateRange;
  bool _isLoading = false;
  bool _isHalfDay = false;

  final List<String> _leaveTypes = const [
    'Sick Leave',
    'Annual Leave',
    'Personal Leave',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.brand),
        ),
        child: child!,
      ),
    );

    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select dates')));
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await LeaveService.createLeave({
      'leave_type': _selectedLeaveType,
      'start_date': _dateRange!.start.toIso8601String().split('T')[0],
      'end_date': _isHalfDay
          ? _dateRange!.start.toIso8601String().split('T')[0]
          : _dateRange!.end.toIso8601String().split('T')[0],
      'is_half_day': _isHalfDay,
      'reason': _reasonController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Request Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                     DropdownButtonFormField<String>(
                      initialValue: _selectedLeaveType,
                      decoration: const InputDecoration(labelText: 'Leave type', border: OutlineInputBorder()),
                      items: _leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _selectedLeaveType = v!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Half-day request'),
                      trailing: Switch.adaptive(
                        value: _isHalfDay,
                        onChanged: (v) => setState(() => _isHalfDay = v),
                      ),
                    ),
                    const Divider(height: 32),
                    const Text('Dates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(_dateRange == null 
                          ? 'Select date range' 
                          : '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}'),
                    ),
                    const Divider(height: 32),
                    const Text('Reason', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Enter reason for leave', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Submit Request',
                onPressed: _submitLeaveRequest,
                loading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
