import 'calendar_event.dart';
import 'calendar_summary.dart';

class CalendarFeed {
  final List<CalendarEvent> events;
  final CalendarSummary summary;

  const CalendarFeed({
    required this.events,
    required this.summary,
  });

  factory CalendarFeed.empty() {
    return CalendarFeed(
      events: [],
      summary: CalendarSummary.empty(),
    );
  }
}
