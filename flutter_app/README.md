# Jyotish AI — Flutter App

## Architecture: Clean Architecture + BLoC

```
lib/
├── main.dart                          # Entry point, DI setup, BLoC providers
├── core/
│   ├── api/
│   │   ├── api_client.dart            # Centralised Dio HTTP client (ALL calls go here)
│   │   ├── api_constants.dart         # All endpoint URLs in one place
│   │   └── token_interceptor.dart     # JWT attach + auto-refresh on 401
│   ├── di/
│   │   └── service_locator.dart       # GetIt — all dependency registrations
│   ├── errors/
│   │   └── app_error.dart             # Typed error hierarchy
│   ├── router/
│   │   ├── app_router.dart            # GoRouter with auth redirect guard
│   │   └── shell_page.dart            # Bottom nav shell
│   ├── storage/
│   │   └── secure_storage.dart        # Encrypted token + user storage
│   ├── theme/
│   │   └── app_theme.dart             # *** EDIT HERE to retheme entire app ***
│   └── widgets/
│       └── app_widgets.dart           # Shared reusable components
└── features/
    ├── auth/                          # Splash, Login, Register
    ├── home/                          # Dashboard with today's forecast
    ├── kundli/                        # Birth chart generator
    ├── horoscope/                     # Daily/weekly/monthly horoscope
    ├── matchmaking/                   # Guna Milan compatibility
    └── ai_chat/                       # AI astrologer chatbot
```

## How to run

```bash
cd flutter_app
flutter pub get
flutter run
```

## Change base URL (point to your Render backend)
Edit: `lib/core/api/api_constants.dart`
```dart
static const String baseUrlProd = 'https://YOUR-APP.onrender.com';
```
For production builds:
```dart
// In main.dart or flavors
ApiConstants.setProduction();
```

## To retheme
Edit `lib/core/theme/app_theme.dart` → change values in `AppColors`.
All screens and widgets read from AppColors. One file = full retheme.

## Each feature follows:
```
feature/
  data/
    datasources/   → API calls (talks to ApiClient only)
    models/        → JSON deserialization
    repositories/  → Implements domain interface
  domain/
    entities/      → Pure Dart classes (no framework)
    repositories/  → Abstract interface
    usecases/      → Single responsibility business actions
  presentation/
    bloc/          → BLoC events/states/logic
    pages/         → Flutter UI screens
    widgets/       → Feature-specific widgets
```
