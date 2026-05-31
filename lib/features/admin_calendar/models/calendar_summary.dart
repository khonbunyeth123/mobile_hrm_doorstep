class CalendarSummary {
  final int total;
  final Map<String, int> statusCounts;

  const CalendarSummary({
    required this.total,
    required this.statusCounts,
  });

  factory CalendarSummary.empty() {
    return const CalendarSummary(total: 0, statusCounts: {});
  }

  factory CalendarSummary.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final rawCounts = json['status_counts'] ??
          json['statusSummary'] ??
          json['counts'] ??
          <String, dynamic>{};

      final counts = <String, int>{};
      if (rawCounts is Map) {
        rawCounts.forEach((key, value) {
          counts[key.toString().toLowerCase()] = _toInt(value);
        });
      }

      return CalendarSummary(
        total: _toInt(json['total'] ?? json['total_events'] ?? json['count']),
        statusCounts: counts,
      );
    }

    return CalendarSummary.empty();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int countFor(String status) => statusCounts[status.toLowerCase()] ?? 0;

  int get pending => countFor('pending');
  int get approved => countFor('approved');
  int get rejected => countFor('rejected');
  int get draft => countFor('draft');
  int get cancelled => countFor('cancelled');
  int get totalTracked => total == 0 ? statusCounts.values.fold(0, (a, b) => a + b) : total;
}
