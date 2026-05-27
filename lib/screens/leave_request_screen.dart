import 'package:flutter/material.dart';
import '../services/leave_service.dart';

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

  final List<String> _leaveTypes = [
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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final today = DateTime.now();
    final minDate = isStartDate ? today : (_startDate ?? today);
    DateTime initialDate = minDate;
    if (isStartDate && _startDate != null) {
      initialDate = _startDate!.isBefore(minDate) ? minDate : _startDate!;
    }
    if (!isStartDate && _endDate != null) {
      initialDate = _endDate!.isBefore(minDate) ? minDate : _endDate!;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
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
  }

  // ── FIXED: real API call instead of Future.delayed ──
  Future<void> _submitLeaveRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a start date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_isHalfDay && _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select an end date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_isHalfDay && _endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('End date cannot be earlier than start date'),
            backgroundColor: Colors.red,
          ),
        );
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
          SnackBar(
            content: Text('Leave request submitted successfully!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_extractSubmitError(result)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Leave Request'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_note, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Apply for Leave',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fill out the form below to submit your leave request',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Form Container
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Leave Type Dropdown
                    Text(
                      'Leave Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLeaveType,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      items: _leaveTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLeaveType = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 20),

                    // Half Day Toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _isHalfDay,
                          activeColor: Colors.blue,
                          onChanged: (bool? value) {
                            setState(() {
                              _isHalfDay = value ?? false;
                              if (_isHalfDay) {
                                _endDate = null;
                              }
                            });
                          },
                        ),
                        Text(
                          'Half Day Leave',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Start Date
                    Text(
                      'Start Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            SizedBox(width: 12),
                            Text(
                              _startDate == null
                                  ? 'Select start date'
                                  : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _startDate == null
                                    ? Colors.grey[600]
                                    : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // End Date (only if not half day)
                    if (!_isHalfDay) ...[
                      Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 12),
                              Text(
                                _endDate == null
                                    ? 'Select end date'
                                    : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _endDate == null
                                      ? Colors.grey[600]
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Leave Duration Summary
                    if (_startDate != null) ...[
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            SizedBox(width: 12),
                            Text(
                              'Duration: ${_calculateLeaveDays()} day${_calculateLeaveDays() > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Reason Field
                    Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Please provide a reason for your leave request...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.edit_note),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
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
                    SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitLeaveRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit Leave Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Additional Information Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Important Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Leave requests should be submitted at least 2 days in advance\n'
                    '• Emergency leave requests will be reviewed on a case-by-case basis\n'
                    '• You will receive an email confirmation once your request is processed\n'
                    '• Check your leave balance before submitting a request',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
