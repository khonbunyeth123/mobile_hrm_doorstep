enum CalendarTargetType { company, employee, department, branch, team }

class CalendarTarget {
  final CalendarTargetType type;
  final String? id;
  final String label;

  const CalendarTarget({
    required this.type,
    required this.label,
    this.id,
  });

  factory CalendarTarget.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? json['target_type'] ?? json['target'] ?? '')
        .toString()
        .toLowerCase();
    final type = CalendarTargetType.values.firstWhere(
      (item) => item.name == rawType,
      orElse: () => CalendarTargetType.company,
    );

    return CalendarTarget(
      type: type,
      id: json['id']?.toString() ?? json['target_id']?.toString(),
      label: (json['label'] ?? json['name'] ?? json['title'] ?? 'Company').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (id != null) 'id': id,
      'label': label,
    };
  }

  String get displayLabel {
    switch (type) {
      case CalendarTargetType.company:
        return 'Company-wide';
      case CalendarTargetType.employee:
        return label;
      case CalendarTargetType.department:
        return 'Department: $label';
      case CalendarTargetType.branch:
        return 'Branch: $label';
      case CalendarTargetType.team:
        return 'Team: $label';
    }
  }
}
