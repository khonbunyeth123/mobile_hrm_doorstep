class CalendarLookupOption {
  final String value;
  final String label;

  const CalendarLookupOption({
    required this.value,
    required this.label,
  });

  factory CalendarLookupOption.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return CalendarLookupOption(
        value: (json['value'] ?? json['id'] ?? json['uuid'] ?? json['code']).toString(),
        label: (json['label'] ?? json['name'] ?? json['title'] ?? json['text'] ?? '').toString(),
      );
    }

    return CalendarLookupOption(
      value: json.toString(),
      label: json.toString(),
    );
  }
}

class CalendarFilterOptions {
  final List<CalendarLookupOption> employees;
  final List<CalendarLookupOption> departments;
  final List<CalendarLookupOption> branches;
  final List<CalendarLookupOption> eventTypes;
  final List<CalendarLookupOption> statuses;
  final List<CalendarLookupOption> teams;

  const CalendarFilterOptions({
    required this.employees,
    required this.departments,
    required this.branches,
    required this.eventTypes,
    required this.statuses,
    required this.teams,
  });

  factory CalendarFilterOptions.empty() {
    return const CalendarFilterOptions(
      employees: [],
      departments: [],
      branches: [],
      eventTypes: [],
      statuses: [],
      teams: [],
    );
  }

  factory CalendarFilterOptions.fromJson(Map<String, dynamic> json) {
    List<CalendarLookupOption> parseList(String key) {
      final value = json[key];
      if (value is List) {
        return value.map(CalendarLookupOption.fromJson).toList();
      }
      return const [];
    }

    return CalendarFilterOptions(
      employees: parseList('employees'),
      departments: parseList('departments'),
      branches: parseList('branches'),
      eventTypes: parseList('event_types'),
      statuses: parseList('statuses'),
      teams: parseList('teams'),
    );
  }
}
