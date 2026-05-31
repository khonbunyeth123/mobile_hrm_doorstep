class CalendarQuery {
  final DateTime startDate;
  final DateTime endDate;
  final String? employeeId;
  final String? department;
  final String? branch;
  final String? eventType;
  final String? status;

  const CalendarQuery({
    required this.startDate,
    required this.endDate,
    this.employeeId,
    this.department,
    this.branch,
    this.eventType,
    this.status,
  });

  CalendarQuery copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? department,
    String? branch,
    String? eventType,
    String? status,
  }) {
    return CalendarQuery(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      branch: branch ?? this.branch,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
    );
  }

  Map<String, String?> toQueryParameters() {
    String fmt(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return {
      'start': fmt(startDate),
      'end': fmt(endDate),
      'employee_id': employeeId,
      'department': department,
      'branch': branch,
      'event_type': eventType,
      'status': status,
    };
  }
}
