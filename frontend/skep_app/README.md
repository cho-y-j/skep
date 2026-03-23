# SKEP - Equipment Dispatch & Inspection Platform

A complete Flutter application for managing equipment dispatch and safety inspections across Web, iOS, and Android platforms.

## Features

### Authentication
- User login and registration
- JWT token management with automatic refresh
- Role-based access control (6 user roles)
- Secure token storage

### Dashboards
- **Admin Dashboard**: Complete system overview with equipment, deployments, documents, and statistics
- **Supplier Dashboard**: Equipment inventory and document management
- **BP Company Dashboard**: Deployment planning and worker management

### Work Records & Dispatch
- Check-in/Check-out with GPS location verification
- Real-time work timer
- NFC tag scanning for authentication
- Work status tracking (Checked In → In Progress → Completed)

### Safety Inspections
- Mandatory NFC scanning to start
- Sequential item-based inspection workflow
- Photo attachment for each item
- Pass/Fail tracking with notes
- GPS location validation

### Real-time Location Tracking
- WebSocket-based live location updates via STOMP
- OpenStreetMap integration with flutter_map
- Worker marker clustering
- Online/Offline status indication

### Core Components
- BLoC pattern for state management
- Dio HTTP client with JWT interceptor
- Secure storage for sensitive data
- GoRouter for navigation
- Material Design UI components

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── app.dart                     # App configuration
├── core/
│   ├── constants/              # Colors, text styles, API endpoints
│   ├── network/                # Dio client, interceptors, exceptions
│   ├── storage/                # Secure storage implementation
│   ├── utils/                  # Date, location utilities
│   └── widgets/                # Reusable UI components
├── features/
│   ├── auth/                   # Authentication (BLoC, models, screens)
│   ├── dashboard/              # Dashboard screens by role
│   ├── dispatch/               # Work records (BLoC, event, state, screens)
│   ├── inspection/             # Safety inspections (BLoC, event, state, screens)
│   ├── location/               # Location tracking (BLoC, event, state, screens)
│   ├── equipment/              # Equipment management (placeholder)
│   ├── document/               # Document management (placeholder)
│   └── settlement/             # Settlement tracking (placeholder)
└── router/                     # GoRouter configuration

pubspec.yaml                    # Dependencies configuration
Dockerfile                      # Docker build configuration
nginx.conf                      # Nginx reverse proxy configuration
```

## Prerequisites

- Flutter 3.19+
- Dart 3.x
- API Gateway running on http://localhost:8080
- Firebase project setup (for push notifications)

## Getting Started

### Installation

1. Install Flutter from https://flutter.dev/docs/get-started/install

2. Clone and navigate to project:
```bash
cd skep_app
```

3. Install dependencies:
```bash
flutter pub get
```

4. (Optional) Generate code for models:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Configuration

1. **Firebase Setup** (Optional for web, required for iOS/Android):
   - Create Firebase project in Firebase Console
   - Update `lib/firebase_options.dart` with your Firebase configuration
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

2. **API Configuration**:
   - Update API endpoint in `lib/core/constants/api_endpoints.dart` if needed
   - Ensure API Gateway is running on http://localhost:8080

### Running

**Web:**
```bash
flutter run -d chrome
```

**iOS:**
```bash
flutter run -d ios
```

**Android:**
```bash
flutter run -d android
```

### Building

**Web:**
```bash
flutter build web --release
```

**iOS:**
```bash
flutter build ios --release
```

**Android:**
```bash
flutter build apk --release
# or for production
flutter build appbundle --release
```

## Docker Deployment

Build and run the Docker container:

```bash
docker build -t skep-app .
docker run -p 80:80 skep-app
```

Access the application at http://localhost

## API Integration

The app communicates with the backend API:

### Key Endpoints

- **Authentication**
  - `POST /api/auth/login`
  - `POST /api/auth/register`
  - `POST /api/auth/refresh`
  - `GET /api/auth/me`

- **Work Records**
  - `GET /api/work-records`
  - `POST /api/work-records`
  - `POST /api/work-records/{id}/start`
  - `POST /api/work-records/{id}/end`

- **Safety Inspections**
  - `POST /api/safety-inspections/{id}/start`
  - `GET /api/safety-inspections/{id}/items`
  - `POST /api/safety-inspections/{id}/items/{itemId}`
  - `POST /api/safety-inspections/{id}/complete`

- **Location Tracking**
  - `WS /ws/locations` (WebSocket/STOMP)

## Dependencies

### State Management
- `flutter_bloc: ^8.1.4` - BLoC pattern implementation
- `equatable: ^2.0.5` - Value equality

### Networking
- `dio: ^5.4.0` - HTTP client
- `retrofit: ^4.1.0` - Type-safe HTTP client (generator)

### Navigation
- `go_router: ^13.2.0` - Declarative routing

### Storage
- `flutter_secure_storage: ^9.0.0` - Secure token storage
- `hive_flutter: ^1.1.0` - Local database

### UI
- `flutter_map: ^6.1.0` - OpenStreetMap integration
- `fl_chart: ^0.67.0` - Charts and statistics
- `image_picker: ^1.0.7` - Photo capture
- `file_picker: ^8.0.0` - File selection

### Hardware
- `nfc_manager: ^3.3.0` - NFC tag reading
- `geolocator: ^11.0.0` - GPS location

### Notifications
- `firebase_core: ^2.27.0` - Firebase core
- `firebase_messaging: ^14.7.20` - Push notifications
- `flutter_local_notifications: ^17.0.0` - Local notifications

### WebSocket
- `stomp_dart_client: ^0.4.4` - STOMP client

### Utilities
- `intl: ^0.19.0` - Internationalization
- `json_annotation: ^4.8.1` - JSON serialization
- `freezed_annotation: ^2.4.1` - Immutable classes

## User Roles

1. **PLATFORM_ADMIN** - System administrator with full access
2. **EQUIPMENT_SUPPLIER** - Equipment supplier management
3. **BP_COMPANY** - Business partner company
4. **DRIVER** - Equipment operator/driver
5. **GUIDE** - Site guide/navigator
6. **SAFETY_INSPECTOR** - Safety inspection specialist

## Development Notes

### Adding New Features

1. Create feature folder under `lib/features/`
2. Implement BLoC pattern (event, state, bloc)
3. Create repository and models
4. Implement UI screens
5. Add routes to `lib/router/app_router.dart`

### Code Style

- Use BLoC pattern for state management
- Implement `Equatable` for model equality
- Use named parameters in function signatures
- Keep widgets under 200 lines (split if needed)
- Use `const` constructors everywhere possible

### Testing

Run tests with:
```bash
flutter test
```

## Troubleshooting

### Common Issues

1. **API Connection Failed**
   - Ensure API Gateway is running on port 8080
   - Check firewall settings
   - Verify API endpoint configuration

2. **NFC Not Working**
   - Check device NFC is enabled
   - Ensure NFC tags are compatible
   - Android: Check NFC permissions

3. **Location Permission Denied**
   - Grant location permission in app settings
   - iOS: Update `Info.plist` with location descriptions
   - Android: Ensure permissions in `AndroidManifest.xml`

4. **WebSocket Connection Failed**
   - Verify WebSocket endpoint is correct
   - Check firewall allows WebSocket connections
   - Ensure STOMP server is running

## Support

For issues and feature requests, please contact the development team.

## License

Proprietary - All rights reserved
