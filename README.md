# HRM Doorstep

Flutter client for the HRM calendar feature and the existing employee app shell.

## What’s Included

- Admin calendar home screen with month, week, and day views
- Event details bottom sheet
- Create and edit event form
- Leave approval and rejection flow
- Filter panel for employee, department, branch, event type, and status
- Token-based API client with secure token storage
- Clean feature structure for models, repository, controller, and UI

## Folder Structure

```text
lib/
  core/
    auth/
      auth_service.dart
      token_storage.dart
    network/
      api_client.dart
      api_result.dart
  features/
    admin_calendar/
      data/
        calendar_repository.dart
      models/
        calendar_event.dart
        calendar_feed.dart
        calendar_filter_option.dart
        calendar_query.dart
        calendar_summary.dart
        calendar_target.dart
        leave_item.dart
      screens/
        admin_calendar_home_screen.dart
        calendar_event_form_screen.dart
      state/
        calendar_controller.dart
  screens/
    home_gate.dart
```

## Backend API

The admin calendar uses these endpoints:

- `GET /api/calendar/events?start=YYYY-MM-DD&end=YYYY-MM-DD&employee_id=&department=&branch=&event_type=&status=`
- `GET /api/calendar/events/{uuid}`
- `POST /api/calendar/events`
- `PUT /api/calendar/events/{uuid}`
- `DELETE /api/calendar/events/{uuid}`
- `GET /api/calendar/filters`
- `POST /api/calendar/leaves/{uuid}/approve`
- `POST /api/calendar/leaves/{uuid}/reject`

## Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app:

```bash
flutter run
```

## Notes

- Admin users are routed to the new calendar shell after login.
- Leave events are treated as read-only in the UI.
- Event mapping is isolated in the model layer so backend shape changes stay localized.
- Token storage writes to secure storage and keeps a SharedPreferences fallback for compatibility with the existing app.

## Customization

- Update `lib/config/app_config.dart` if the API base URL changes.
- Adjust model parsing inside `lib/features/admin_calendar/models/` if the backend response shape changes.
- Extend the controller in `lib/features/admin_calendar/state/calendar_controller.dart` for more filtering or search behavior.
