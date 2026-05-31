class LeaveItem {
  final String uuid;
  final String employeeName;
  final String leaveType;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String? department;
  final String? branch;
  final String? eventUuid;

  const LeaveItem({
    required this.uuid,
    required this.employeeName,
    required this.leaveType,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.department,
    this.branch,
    this.eventUuid,
  });

  factory LeaveItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed ?? DateTime.now();
    }

    return LeaveItem(
      uuid: (json['uuid'] ?? json['id'] ?? json['leave_uuid']).toString(),
      employeeName: (json['employee_name'] ?? json['employee'] ?? json['name'] ?? 'Employee').toString(),
      leaveType: (json['leave_type'] ?? json['type'] ?? 'Leave').toString(),
      status: (json['status'] ?? json['leave_status'] ?? 'pending').toString(),
      startDate: parseDate(json['start_date'] ?? json['from_date'] ?? json['start_at']),
      endDate: parseDate(json['end_date'] ?? json['to_date'] ?? json['end_at']),
      reason: json['reason']?.toString() ?? json['description']?.toString(),
      department: json['department']?.toString(),
      branch: json['branch']?.toString(),
      eventUuid: json['event_uuid']?.toString(),
    );
  }
}
