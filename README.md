# HRM Doorstep Mobile

Flutter mobile app for attendance, leave requests, profile, and notifications.

## Environment Configuration

The app base URL is configured with `--dart-define` values (no code edits needed).

Supported define keys:

- `APP_ENV=dev|prod`
- `BASE_URL=<full_api_base_url>` (highest priority override)
- `DEV_BASE_URL=<full_api_base_url>`
- `PROD_BASE_URL=<full_api_base_url>`

Examples:

```bash
flutter run --dart-define=APP_ENV=dev --dart-define=DEV_BASE_URL=http://192.168.0.104:8080/api
```

```bash
flutter run --dart-define=APP_ENV=prod --dart-define=PROD_BASE_URL=https://api.example.com/api
```

```bash
flutter build apk --dart-define=BASE_URL=https://api.example.com/api
```
