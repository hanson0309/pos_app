# POS App - Flutter

A comprehensive Point of Sale (POS) application for retail and service businesses, integrated with Malaysia's E-Invoice system.

## Features

- 🛒 **Offline-First POS**: Complete sales operations without internet
- 📱 **Cross-Platform**: Android, iOS, Windows, macOS support
- 🔄 **Auto Sync**: Background synchronization when online
- 📄 **E-Invoice Integration**: Automatic invoice generation
- 📦 **Inventory Management**: Stock tracking and alerts
- 📅 **Appointments**: Service business scheduling (optional)
- 👥 **Multi-Cashier**: Role-based access control
- 🖨️ **Hardware Support**: Printers, scanners, cash drawers

## Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Riverpod
- **Local Database**: SQLite (sqflite)
- **Network**: Dio + Retrofit
- **Secure Storage**: flutter_secure_storage

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode (for mobile development)
- Visual Studio (for Windows development)

### Installation

```bash
# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Configuration

1. Copy `.env.example` to `.env`
2. Update the API endpoint in `lib/config/app_config.dart`

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── config/                   # App configuration
├── models/                   # Data models
├── services/                 # Business logic services
├── providers/                # Riverpod providers
├── screens/                  # UI screens
├── widgets/                  # Reusable widgets
└── utils/                    # Utility functions
```

## Development

```bash
# Run in development mode
flutter run

# Build for production
flutter build apk --release      # Android
flutter build ios --release      # iOS
flutter build windows --release  # Windows
flutter build macos --release    # macOS
```

## License

MIT
